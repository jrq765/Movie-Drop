module.exports = async function handler(req, res) {
  const BACKEND_BASE_URL = process.env.BACKEND_BASE_URL;

  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const anonId = (req.query.anonId || '').toString().trim();
  const region = (req.query.region || 'US').toString();
  const count = Math.max(1, Math.min(parseInt(req.query.count || '12', 10) || 12, 20));

  if (!BACKEND_BASE_URL) {
    return res.status(500).json({
      error: 'Recommendation store not configured',
      restore: [
        'Set BACKEND_BASE_URL to your persistent API (e.g., https://api.moviedrop.app)',
        'API must expose GET /recommend?anonId=...&region=...&count=...',
        'Alternatively deploy moviedrop-backend and point BACKEND_BASE_URL to it',
        'Then redeploy this project'
      ]
    });
  }

  try {
    const url = `${BACKEND_BASE_URL.replace(/\/$/, '')}/recommend?anonId=${encodeURIComponent(anonId)}&region=${encodeURIComponent(region)}&count=${count}`;
    const response = await fetch(url, { headers: { 'Accept': 'application/json' } });
    if (response.status === 204) {
      res.statusCode = 204;
      return res.end();
    }
    const data = await response.json().catch(() => ({}));
    if (!response.ok) {
      return res.status(response.status).json(data);
    }
    return res.status(200).json(data);
  } catch (err) {
    console.error('recommend proxy error:', err);
    return res.status(500).json({ error: 'Failed to get recommendations' });
  }
}


