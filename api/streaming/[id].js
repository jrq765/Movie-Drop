export default async function handler(req, res) {
  // Set CORS headers
  res.setHeader('Access-Control-Allow-Origin', 'https://moviedrop.app');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }
  
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  const { id } = req.query;
  const region = req.query.region || 'US';
  
  if (!id) {
    return res.status(400).json({ error: 'Missing movie id' });
  }

  const TMDB_KEY = process.env.TMDB_API_KEY;
  if (!TMDB_KEY) {
    return res.status(500).json({
      error: 'Missing TMDB_API_KEY',
      restore: [
        'Add TMDB_API_KEY to your Vercel project Environment Variables',
        'Redeploy, then GET /api/health should return { ok: true }'
      ]
    });
  }

  try {
    // Fetch watch/providers for the movie
    const url = `https://api.themoviedb.org/3/movie/${id}/watch/providers?api_key=${TMDB_KEY}`;
    const response = await fetch(url);
    
    if (!response.ok) {
      return res.status(response.status).json({ error: 'TMDB providers fetch failed' });
    }
    
    const data = await response.json();
    const regionData = data?.results?.[region.toUpperCase()];
    const tmdbRegionLink = regionData?.link || `https://www.themoviedb.org/movie/${id}/watch?locale=${region}`;

    if (!regionData) {
      return res.status(200).json({ 
        region: region.toUpperCase(), 
        link: tmdbRegionLink, 
        providers: [] 
      });
    }

    // Extract providers by type
    const kinds = ['flatrate', 'rent', 'buy'];
    const providers = [];

    for (const kind of kinds) {
      const arr = regionData[kind] || [];
      for (const p of arr) {
        providers.push({
          id: p.provider_id,
          name: p.provider_name,
          logo_path: p.logo_path,
          kind,
          url: tmdbRegionLink
        });
      }
    }

    // Dedupe by provider id + kind
    const key = (x) => `${x.id}:${x.kind}`;
    const dedup = Object.values(
      providers.reduce((acc, cur) => ((acc[key(cur)] = acc[key(cur)] || cur), acc), {})
    );

    res.setHeader('Cache-Control', 's-maxage=300, stale-while-revalidate=600');
    return res.status(200).json({ 
      region: region.toUpperCase(), 
      link: tmdbRegionLink, 
      providers: dedup 
    });
    
  } catch (error) {
    return res.status(500).json({ error: 'Internal server error' });
  }
}