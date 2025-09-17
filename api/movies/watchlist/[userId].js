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
    const { userId } = req.query;
    
    if (req.method === 'GET') {
      // Get user's watchlist
      const response = await fetch(`${BACKEND_BASE_URL}/api/movies/watchlist/${userId}`);
      const data = await response.json();
      res.status(response.status).json(data);
    } else if (req.method === 'DELETE') {
      // Remove from watchlist (if movieId is provided in query)
      const { movieId } = req.query;
      if (!movieId) {
        return res.status(400).json({ error: 'movieId is required for DELETE' });
      }
      
      const response = await fetch(`${BACKEND_BASE_URL}/api/movies/watchlist/${userId}/${movieId}`, {
        method: 'DELETE'
      });
      const data = await response.json();
      res.status(response.status).json(data);
    } else {
      res.status(405).json({ error: 'Method not allowed' });
    }
  } catch (error) {
    console.error('watchlist/[userId] error:', error);
    res.status(500).json({ error: 'Failed to process watchlist request' });
  }
};
