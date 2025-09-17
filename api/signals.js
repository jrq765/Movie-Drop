module.exports = async function handler(req, res) {
  const BACKEND_BASE_URL = process.env.BACKEND_BASE_URL;

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  if (!BACKEND_BASE_URL) {
    return res.status(500).json({
      error: 'Signals store not configured',
      restore: [
        'Set BACKEND_BASE_URL to your persistent API (e.g., https://api.moviedrop.app)',
        'API must expose POST /signals to persist events',
        'Alternatively deploy moviedrop-backend and point BACKEND_BASE_URL to it',
        'Then redeploy this project'
      ]
    });
  }

  try {
    const url = `${BACKEND_BASE_URL.replace(/\/$/, '')}/signals`;
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
      body: JSON.stringify(req.body || {})
    });
    const data = await response.json().catch(() => ({}));
    if (!response.ok) {
      return res.status(response.status).json(data);
    }
    return res.status(200).json({ ok: true });
  } catch (err) {
    console.error('signals proxy error:', err);
    return res.status(500).json({ error: 'Failed to record signal' });
  }
}


