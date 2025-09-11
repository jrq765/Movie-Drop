export default function handler(req, res) {
  res.status(200).json({ 
    ok: true, 
    service: 'MovieDrop API v2', 
    timestamp: Date.now(),
    deployment: 'fresh'
  });
}