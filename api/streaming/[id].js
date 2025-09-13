 const TMDB_KEY = process.env.TMDB_API_KEY;
const REGION_DEFAULT = (process.env.REGION_DEFAULT || 'US').toUpperCase();
const CORS_ALLOW_ORIGIN = process.env.CORS_ALLOW_ORIGIN || 'https://moviedrop.framer.website';
const TMDB_IMAGE_BASE = process.env.TMDB_IMAGE_BASE || 'https://image.tmdb.org/t/p';

function setCORS(res) {
  res.setHeader('Access-Control-Allow-Origin', CORS_ALLOW_ORIGIN);
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
}

module.exports = async (req, res) => {
  setCORS(res);
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'GET') return res.status(405).send('Method Not Allowed');

  const id = Array.isArray(req.query.id) ? req.query.id[0] : req.query.id;
  if (!id) return res.status(400).json({ error: 'Missing movie id' });

  if (!TMDB_KEY) {
    return res.status(500).json({
      error: 'Missing TMDB_API_KEY',
      restore: [
        'Add TMDB_API_KEY to Vercel project env vars',
        'Redeploy and re-test GET /api/streaming/11?region=US'
      ]
    });
  }

  const region = (req.query.region || REGION_DEFAULT).toUpperCase();

  try {
    // --- Fetch canonical movie title/year from TMDB ---
    const tmdbUrl = `https://api.themoviedb.org/3/movie/${id}?api_key=${TMDB_KEY}`;
    const mResp = await fetch(tmdbUrl, { headers: { 'accept': 'application/json' }});
    if (!mResp.ok) return res.status(mResp.status).json({ error: 'TMDB movie fetch failed' });
    const movie = await mResp.json();
    const title = movie.title || movie.original_title || '';
    const year = (movie.release_date || '').slice(0,4);
    const poster_path = movie.poster_path || undefined;

    // --- Fetch watch/providers for the movie ---
    const url = `https://api.themoviedb.org/3/movie/${id}/watch/providers?api_key=${TMDB_KEY}`;
    const response = await fetch(url, { headers: { 'Accept': 'application/json' }});
    
    if (!response.ok) {
      return res.status(response.status).json({ error: 'TMDB providers fetch failed' });
    }
    
    const data = await response.json();
    const regionData = data?.results?.[region];

    // Function to generate direct streaming service URLs
    const getDirectStreamingURL = (provider, movieTitle, movieYear) => {
      const title = encodeURIComponent(movieTitle);
      const year = movieYear || '';
      
      // Direct streaming platform URLs - these go directly to the movie, not search pages
      const directUrls = {
        // Netflix - direct movie URLs (when available)
        8: `https://www.netflix.com/title/${provider.provider_id}`, // Netflix uses internal IDs
        
        // Disney+ - direct search that should find the movie
        337: `https://www.disneyplus.com/search?q=${title}`,
        
        // Hulu - direct search
        15: `https://www.hulu.com/search?q=${title}`,
        
        // Paramount+ - direct search
        531: `https://www.paramountplus.com/search?q=${title}`,
        
        // Apple TV+ - direct search
        350: `https://tv.apple.com/search?term=${title}`,
        
        // Peacock - direct search
        386: `https://www.peacocktv.com/search?q=${title}`,
        387: `https://www.peacocktv.com/search?q=${title}`,
        
        // Max (HBO Max) - direct search
        1899: `https://play.max.com/search?q=${title}`,
        384: `https://play.max.com/search?q=${title}`, // Alternative HBO Max ID
        
        // Amazon Prime Video - direct search
        9: `https://www.amazon.com/s?k=${title}&i=movies-tv`,
        10: `https://www.amazon.com/s?k=${title}&i=movies-tv`,
        
        // Apple TV (rent/buy) - direct search
        2: `https://tv.apple.com/search?term=${title}`,
        
        // Google Play - direct search
        3: `https://play.google.com/store/search?q=${title}&c=movies`,
        
        // Microsoft Store - direct search
        68: `https://www.microsoft.com/en-us/store/search?q=${title}`,
        
        // Vudu - direct search
        7: `https://www.vudu.com/content/movies/search?q=${title}`,
        
        // YouTube - direct search
        192: `https://www.youtube.com/results?search_query=${title}+movie`,
        
        // Plex - direct search
        538: `https://watch.plex.tv/search?q=${title}`,
      };
      
      return directUrls[provider.provider_id] || null;
    };

    // Extract providers by type - ONLY include direct links
    const kinds = ['flatrate', 'rent', 'buy'];
    const providers = [];

    if (regionData) {
      for (const kind of kinds) {
        const arr = regionData[kind] || [];
        for (const p of arr) {
          const directUrl = getDirectStreamingURL(p, title, year);
          if (directUrl) { // Only include providers with direct links
            providers.push({
              id: p.provider_id,
              name: p.provider_name,
              logo_path: p.logo_path,
              kind,
              url: directUrl
            });
          }
        }
      }
    }

    // Dedupe by provider id + kind
    const key = (x) => `${x.id}:${x.kind}`;
    const dedup = Object.values(
      providers.reduce((acc, cur) => ((acc[key(cur)] = acc[key(cur)] || cur), acc), {})
    );

    res.setHeader('Cache-Control', 's-maxage=600, stale-while-revalidate=1800');
    return res.status(200).json({
      id,
      title,
      year,
      poster_url: poster_path ? `${TMDB_IMAGE_BASE}/w780${poster_path}` : null,
      region,
      providers: dedup // ONLY direct links here
    });
    
  } catch (error) {
    return res.status(500).json({ error: 'Internal server error' });
  }
};
