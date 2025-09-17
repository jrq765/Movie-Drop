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

  const { id } = req.query;
  if (!id) {
    return res.status(400).json({ error: 'Missing movie id' });
  }

  try {
    const url = `https://api.themoviedb.org/3/movie/${encodeURIComponent(id)}?api_key=${TMDB_KEY}`;
    const response = await fetch(url);
    const data = await response.json();

    if (!response.ok) {
      throw new Error(`TMDB API error: ${data.status_message || 'Unknown error'}`);
    }

    res.setHeader('Cache-Control', 's-maxage=1800, stale-while-revalidate=3600');
    res.status(200).json(data);
  } catch (error) {
    console.error('movies/[id] error:', error);
    res.status(500).json({ error: 'Failed to fetch movie details' });
  }
}


