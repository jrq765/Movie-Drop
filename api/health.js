export default function handler(req, res) {
  res.status(200).json({ 
    ok: true, 
    service: 'MovieDrop API', 
    timestamp: Date.now() 
  });
}