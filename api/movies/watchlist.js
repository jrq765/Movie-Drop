module.exports = async function handler(req, res) {
  const BACKEND_BASE_URL = process.env.BACKEND_BASE_URL;
  
  if (!BACKEND_BASE_URL) {
    return res.status(500).json({
      error: 'BACKEND_BASE_URL not configured',
      fix: [
        'Set BACKEND_BASE_URL in Vercel Project Settings → Environment Variables',
        'Point to your Railway backend URL (e.g., https://movie-drop-production.up.railway.app)',
        'Redeploy after setting the variable'
      ]
    });
  }

  try {
    if (req.method === 'POST') {
      // Add to watchlist
      const response = await fetch(`${BACKEND_BASE_URL}/api/movies/watchlist`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(req.body)
      });

      const data = await response.json();
      res.status(response.status).json(data);
    } else {
      res.status(405).json({ error: 'Method not allowed' });
    }
  } catch (error) {
    console.error('watchlist error:', error);
    res.status(500).json({ error: 'Failed to process watchlist request' });
  }
};
