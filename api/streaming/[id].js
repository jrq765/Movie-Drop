module.exports = async function handler(req, res) {
  const TMDB_KEY = process.env.TMDB_API_KEY;
  if (!TMDB_KEY) {
    return res.status(500).json({ error: 'TMDB_API_KEY missing' });
  }

  try {
    const { id } = req.query;
    const region = req.query.region || 'US';
    const kind = req.query.kind || 'flatrate';
    const primaryOnly = req.query.primaryOnly === 'true';
    const limit = primaryOnly ? 1 : Math.min(parseInt(req.query.limit) || 6, 6);
    
    if (!id) {
      return res.status(400).json({ error: 'Movie ID is required' });
    }

    // Fetch movie details for title/year
    const movieUrl = `https://api.themoviedb.org/3/movie/${id}?api_key=${TMDB_KEY}`;
    const movieResponse = await fetch(movieUrl);
    const movieData = await movieResponse.json();
    
    if (!movieResponse.ok) {
      throw new Error(`TMDB Movie API error: ${movieData.status_message || 'Unknown error'}`);
    }

    // Fetch streaming providers
    const providersUrl = `https://api.themoviedb.org/3/movie/${id}/watch/providers?api_key=${TMDB_KEY}`;
    const providersResponse = await fetch(providersUrl);
    const providersData = await providersResponse.json();

    if (!providersResponse.ok) {
      throw new Error(`TMDB Providers API error: ${providersData.status_message || 'Unknown error'}`);
    }

    const regionData = providersData.results[region] || {};
    
    // Get providers by kind
    let selectedProviders = [];
    if (kind === 'flatrate') {
      selectedProviders = regionData.flatrate || [];
    } else if (kind === 'rent') {
      selectedProviders = regionData.rent || [];
    } else if (kind === 'buy') {
      selectedProviders = regionData.buy || [];
    }
    
    // Sort by display priority (lower = more prominent)
    selectedProviders.sort((a, b) => a.display_priority - b.display_priority);
    
    // Apply limit
    const limitedProviders = selectedProviders.slice(0, limit);
    
    // Create response structure
    const response = {
      id: parseInt(id),
      title: movieData.title,
      year: new Date(movieData.release_date).getFullYear(),
      region: region,
      primary: limitedProviders.length > 0 ? {
        name: limitedProviders[0].provider_name,
        kind: kind,
        url: getDirectUrl(limitedProviders[0].provider_id, movieData.title),
        logo_path: limitedProviders[0].logo_path,
        provider_id: limitedProviders[0].provider_id,
        display_priority: limitedProviders[0].display_priority
      } : null,
      providers: limitedProviders.map(provider => ({
        name: provider.provider_name,
        kind: kind,
        url: getDirectUrl(provider.provider_id, movieData.title),
        logo_path: provider.logo_path,
        provider_id: provider.provider_id,
        display_priority: provider.display_priority
      })),
      counts: {
        flatrate: (regionData.flatrate || []).length,
        rent: (regionData.rent || []).length,
        buy: (regionData.buy || []).length
      }
    };

    res.setHeader('Cache-Control', 's-maxage=600, stale-while-revalidate=1800');
    res.status(200).json(response);

  } catch (error) {
    console.error('streaming/[id] error:', error);
    res.status(500).json({ error: 'Failed to fetch streaming providers' });
  }
};

// Helper function to get direct URLs for providers
function getDirectUrl(providerId, movieTitle) {
  const encodedTitle = encodeURIComponent(movieTitle);
  
  switch (providerId) {
    case 8: return `https://www.netflix.com/search?q=${encodedTitle}`;
    case 9:
    case 10: return `https://www.amazon.com/s?k=${encodedTitle}&i=movies-tv`;
    case 15: return `https://www.hulu.com/search?q=${encodedTitle}`;
    case 337: return `https://www.disneyplus.com/search?q=${encodedTitle}`;
    case 1899:
    case 384: return `https://play.max.com/search?q=${encodedTitle}`;
    case 2:
    case 350: return `https://tv.apple.com/search?term=${encodedTitle}`;
    case 192: return `https://www.youtube.com/results?search_query=${encodedTitle}+movie`;
    case 531: return `https://www.paramountplus.com/search?q=${encodedTitle}`;
    case 386:
    case 387: return `https://www.peacocktv.com/search?q=${encodedTitle}`;
    case 3: return `https://play.google.com/store/search?q=${encodedTitle}&c=movies`;
    case 7: return `https://www.vudu.com/content/movies/search?q=${encodedTitle}`;
    case 538: return `https://watch.plex.tv/search?q=${encodedTitle}`;
    default: return null;
  }
}
