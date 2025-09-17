module.exports = async function handler(req, res) {
  const BACKEND_BASE_URL = process.env.BACKEND_BASE_URL;

  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  if (!BACKEND_BASE_URL) {
    return res.status(500).json({
      error: 'Watchlist store not configured',
      restore: [
        'Option A: Set BACKEND_BASE_URL to your existing Express API (e.g., https://api.moviedrop.app)',
        'Ensure it exposes POST /movies/watchlist and GET /movies/watchlist/:userId',
        'Option B: Deploy moviedrop-backend and set BACKEND_BASE_URL to that URL',
        'After setting envs, redeploy and retry'
      ]
    });
  }

  const { userId } = req.query;
  try {
    const url = `${BACKEND_BASE_URL.replace(/\/$/, '')}/movies/watchlist/${encodeURIComponent(userId)}`;
    const response = await fetch(url, { headers: { 'Accept': 'application/json' } });
    const data = await response.json().catch(() => ({}));
    if (!response.ok) {
      return res.status(response.status).json(data);
    }
    return res.status(200).json(data);
  } catch (err) {
    console.error('watchlist GET proxy error:', err);
    return res.status(500).json({ error: 'Failed to load watchlist' });
  }
}


