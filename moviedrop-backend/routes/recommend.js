const express = require('express');
const router = express.Router();
const { Pool } = require('pg');

// Create a connection pool
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});

// GET /recommend - Get personalized movie recommendations
router.get('/', async (req, res) => {
  try {
    const { userId } = req.query;
    
    if (!userId) {
      return res.status(400).json({ error: 'userId is required' });
    }

    // Check if user has enough signals for recommendations
    const signalCountQuery = `
      SELECT COUNT(*) as count 
      FROM user_signals 
      WHERE user_id = $1
    `;
    
    const signalResult = await pool.query(signalCountQuery, [userId]);
    const signalCount = parseInt(signalResult.rows[0].count);
    
    if (signalCount < 3) {
      return res.status(204).json({ 
        error: 'INSUFFICIENT_SIGNALS',
        message: 'Need at least 3 preference signals for recommendations'
      });
    }

    // Get user's liked genres
    const genreQuery = `
      SELECT 
        g.name,
        COUNT(*) as preference_score
      FROM user_signals us
      JOIN movies m ON us.movie_id = m.id
      JOIN movie_genres mg ON m.id = mg.movie_id
      JOIN genres g ON mg.genre_id = g.id
      WHERE us.user_id = $1 AND us.action = 'like'
      GROUP BY g.id, g.name
      ORDER BY preference_score DESC
      LIMIT 5
    `;
    
    const genreResult = await pool.query(genreQuery, [userId]);
    
    if (genreResult.rows.length === 0) {
      return res.status(204).json({ 
        error: 'INSUFFICIENT_SIGNALS',
        message: 'No genre preferences found'
      });
    }

    // Get recommended movies based on preferred genres
    const preferredGenres = genreResult.rows.map(row => row.name);
    const placeholders = preferredGenres.map((_, index) => `$${index + 2}`).join(',');
    
    const recommendQuery = `
      SELECT DISTINCT m.*
      FROM movies m
      JOIN movie_genres mg ON m.id = mg.movie_id
      JOIN genres g ON mg.genre_id = g.id
      WHERE g.name IN (${placeholders})
        AND m.id NOT IN (
          SELECT movie_id FROM user_signals 
          WHERE user_id = $1 AND action IN ('like', 'dismiss')
        )
      ORDER BY m.popularity DESC
      LIMIT 20
    `;
    
    const recommendResult = await pool.query(recommendQuery, [userId, ...preferredGenres]);
    
    res.json({
      recommendations: recommendResult.rows,
      preferredGenres: preferredGenres,
      signalCount: signalCount
    });
    
  } catch (error) {
    console.error('Error getting recommendations:', error);
    res.status(500).json({ error: 'Failed to get recommendations' });
  }
});

module.exports = router;
