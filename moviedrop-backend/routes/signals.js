const express = require('express');
const router = express.Router();
const { Pool } = require('pg');

// Create a connection pool
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});

// POST /signals - Record user preference signals
router.post('/', async (req, res) => {
  try {
    const { userId, movieId, action, timestamp } = req.body;
    
    if (!movieId || !action) {
      return res.status(400).json({ error: 'movieId and action are required' });
    }

    // Insert signal into database (allow null user_id for anonymous users)
    const query = `
      INSERT INTO user_signals (user_id, movie_id, action, created_at)
      VALUES ($1, $2, $3, $4)
      ON CONFLICT (user_id, movie_id, action) 
      DO UPDATE SET created_at = $4
    `;
    
    const values = [userId || null, movieId, action, timestamp || new Date()];
    await pool.query(query, values);
    
    res.json({ success: true });
  } catch (error) {
    console.error('Error recording signal:', error);
    res.status(500).json({ error: 'Failed to record signal' });
  }
});

module.exports = router;
