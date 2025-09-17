module.exports = async function handler(req, res) {
 const TMDB_KEY = process.env.TMDB_API_KEY;
  if (!TMDB_KEY) {
    return res.status(500).json({ error: 'TMDB_API_KEY missing' });
  }

  try {
    const { id } = req.query;
    const region = req.query.region || 'US';
    
    if (!id) {
      return res.status(400).json({ error: 'Movie ID is required' });
    }

    const url = `https://api.themoviedb.org/3/movie/${id}/watch/providers?api_key=${TMDB_KEY}`;
    const response = await fetch(url);
    const data = await response.json();
    
    if (!response.ok) {
      throw new Error(`TMDB API error: ${data.status_message || 'Unknown error'}`);
    }

    const providers = data.results[region] || {};
    
    // Process and clean up the providers data
    const processedProviders = {
      flatrate: providers.flatrate || [],
      rent: providers.rent || [],
      buy: providers.buy || []
    };

    // Remove TMDB fallback links and combine rent/buy for same provider
    const dedupedProviders = {};
    
    // Process flatrate (streaming)
    if (processedProviders.flatrate.length > 0) {
      dedupedProviders.flatrate = processedProviders.flatrate.map(provider => ({
        provider_id: provider.provider_id,
        provider_name: provider.provider_name,
        logo_path: provider.logo_path,
        display_priority: provider.display_priority
      }));
    }

    // Combine rent and buy options for same provider
    const combinedProviders = {};
    
    // Process rent options
    processedProviders.rent.forEach(provider => {
      const key = provider.provider_id;
      if (!combinedProviders[key]) {
        combinedProviders[key] = {
          provider_id: provider.provider_id,
          provider_name: provider.provider_name,
          logo_path: provider.logo_path,
          display_priority: provider.display_priority,
          kind: 'rent'
        };
      } else {
        combinedProviders[key].kind = 'rent/buy';
      }
    });

    // Process buy options
    processedProviders.buy.forEach(provider => {
      const key = provider.provider_id;
      if (!combinedProviders[key]) {
        combinedProviders[key] = {
          provider_id: provider.provider_id,
          provider_name: provider.provider_name,
          logo_path: provider.logo_path,
          display_priority: provider.display_priority,
          kind: 'buy'
        };
      } else {
        combinedProviders[key].kind = 'rent/buy';
      }
    });

    // Convert to array and sort by display priority
    dedupedProviders.purchase = Object.values(combinedProviders)
      .sort((a, b) => a.display_priority - b.display_priority);

    res.setHeader('Cache-Control', 's-maxage=3600, stale-while-revalidate=7200');
    res.status(200).json(dedupedProviders);

  } catch (error) {
    console.error('streaming/[id] error:', error);
    res.status(500).json({ error: 'Failed to fetch streaming providers' });
  }
};
