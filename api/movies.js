module.exports = async function handler(req, res) {
  const TMDB_KEY = process.env.TMDB_API_KEY;
  if (!TMDB_KEY) {
    return res.status(500).json({
      error: 'TMDB_API_KEY missing',
      fix: [
        'Set TMDB_API_KEY in Vercel Project Settings → Environment Variables',
        'Redeploy after setting the key'
      ]
    });
  }

  try {
    const { type, query, region, randomize, exclude, page } = req.query;
    
    if (type === 'search') {
      // Handle search
      if (req.method !== 'GET') {
        return res.status(405).json({ error: 'Method not allowed' });
      }

      const searchQuery = (query || '').toString().trim();
      if (!searchQuery) {
        return res.status(400).json({ error: 'Missing query parameter' });
      }

      const url = `https://api.themoviedb.org/3/search/movie?api_key=${TMDB_KEY}&query=${encodeURIComponent(searchQuery)}`;
      const response = await fetch(url);
      const data = await response.json();

      if (!response.ok) {
        throw new Error(`TMDB API error: ${data.status_message || 'Unknown error'}`);
      }

      res.setHeader('Cache-Control', 's-maxage=600, stale-while-revalidate=1200');
      res.status(200).json(data);
      
    } else {
      // Handle popular movies
      if (req.method !== 'GET') {
        return res.status(405).json({ error: 'Method not allowed' });
      }

      const movieRegion = region || 'US';
      const shouldRandomize = String(randomize || 'false').toLowerCase() === 'true';
      const excludeStr = (exclude || '').toString().trim();
      const excludeIds = excludeStr
        ? excludeStr.split(',').map((s) => parseInt(s, 10)).filter((n) => !Number.isNaN(n))
        : [];

      // Choose a page. If randomize=true, pick a pseudo-random page 1..500 using a salt.
      let moviePage = parseInt(page || '1', 10);
      if (shouldRandomize) {
        const salt = `${req.query.t || ''}-${req.query.r || ''}-${Date.now()}`;
        // Simple deterministic-ish hash → number
        let hash = 0;
        for (let i = 0; i < salt.length; i++) hash = (hash * 31 + salt.charCodeAt(i)) >>> 0;
        moviePage = (hash % 500) + 1; // 1..500
      }

      const url = `https://api.themoviedb.org/3/movie/popular?api_key=${TMDB_KEY}&page=${moviePage}&region=${movieRegion}`;

      const response = await fetch(url);
      const data = await response.json();

      if (!response.ok) {
        throw new Error(`TMDB API error: ${data.status_message || 'Unknown error'}`);
      }

      // Optionally filter out excluded IDs
      let results = Array.isArray(data.results) ? data.results : [];
      if (excludeIds.length > 0) {
        results = results.filter((m) => !excludeIds.includes(m.id));
      }

      // If randomize=true, lightly shuffle within the page to reduce repetition
      if (shouldRandomize && results.length > 1) {
        for (let i = results.length - 1; i > 0; i--) {
          const j = Math.floor(Math.random() * (i + 1));
          [results[i], results[j]] = [results[j], results[i]];
        }
      }

      res.setHeader('Cache-Control', 's-maxage=300, stale-while-revalidate=600');
      res.status(200).json({ ...data, results });
    }
  } catch (error) {
    console.error('movies error:', error);
    res.status(500).json({ error: 'Failed to fetch movies' });
  }
}
