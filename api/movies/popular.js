module.exports = async function handler(req, res) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

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
    const region = req.query.region || 'US';
    const randomize = String(req.query.randomize || 'false').toLowerCase() === 'true';
    const exclude = (req.query.exclude || '').toString().trim();
    const excludeIds = exclude
      ? exclude.split(',').map((s) => parseInt(s, 10)).filter((n) => !Number.isNaN(n))
      : [];

    // Choose a page. If randomize=true, pick a pseudo-random page 1..500 using a salt.
    // TMDB popular endpoint supports many pages; cap to 500 for safety.
    let page = parseInt(req.query.page || '1', 10);
    if (randomize) {
      const salt = `${req.query.t || ''}-${req.query.r || ''}-${Date.now()}`;
      // Simple deterministic-ish hash → number
      let hash = 0;
      for (let i = 0; i < salt.length; i++) hash = (hash * 31 + salt.charCodeAt(i)) >>> 0;
      page = (hash % 500) + 1; // 1..500
    }

    const url = `https://api.themoviedb.org/3/movie/popular?api_key=${TMDB_KEY}&page=${page}&region=${region}`;

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
    if (randomize && results.length > 1) {
      for (let i = results.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [results[i], results[j]] = [results[j], results[i]];
      }
    }

    res.setHeader('Cache-Control', 's-maxage=300, stale-while-revalidate=600');
    res.status(200).json({ ...data, results });
  } catch (error) {
    console.error('movies/popular error:', error);
    res.status(500).json({ error: 'Failed to fetch popular movies' });
  }
}


