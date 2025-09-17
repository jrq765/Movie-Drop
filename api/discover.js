module.exports = async function handler(req, res) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const TMDB_KEY = process.env.TMDB_API_KEY;
  if (!TMDB_KEY) {
    return res.status(500).json({
      error: 'TMDB_API_KEY missing',
      restore: [
        'Set TMDB_API_KEY in Vercel Project Settings → Environment Variables (Production)',
        'Verify with: curl -I https://moviedrop.app/api/health',
        'Test: curl "https://moviedrop.app/api/discover?count=3"'
      ]
    });
  }

  const region = (req.query.region || 'US').toString();
  const count = Math.max(1, Math.min(parseInt(req.query.count || '12', 10) || 12, 20));
  const seedParam = req.query.seed;
  let page;
  if (seedParam !== undefined && seedParam !== null && seedParam !== '') {
    const seedNum = parseInt(seedParam, 10) || 0;
    page = 1 + (Math.abs(seedNum) % 50);
  } else {
    page = 1 + Math.floor(Math.random() * 50);
  }

  const url = `https://api.themoviedb.org/3/discover/movie?api_key=${TMDB_KEY}&region=${encodeURIComponent(region)}&sort_by=popularity.desc&include_adult=false&page=${page}`;

  try {
    const response = await fetch(url);
    const data = await response.json();
    if (!response.ok) {
      throw new Error(data.status_message || 'TMDB error');
    }

    const results = Array.isArray(data.results) ? data.results : [];
    // Sample unique items
    const picked = [];
    const used = new Set();
    while (picked.length < count && used.size < results.length) {
      const idx = Math.floor(Math.random() * results.length);
      const movie = results[idx];
      if (!movie || used.has(movie.id)) continue;
      used.add(movie.id);
      // Compact fields
      picked.push({
        id: movie.id,
        title: movie.title,
        overview: movie.overview,
        release_date: movie.release_date,
        vote_average: movie.vote_average,
        poster_path: movie.poster_path,
        genre_ids: movie.genre_ids
      });
    }

    res.setHeader('Cache-Control', 's-maxage=120, stale-while-revalidate=600');
    return res.status(200).json({ page, count: picked.length, results: picked });
  } catch (err) {
    console.error('discover error:', err);
    return res.status(500).json({ error: 'Failed to fetch discover feed' });
  }
}


