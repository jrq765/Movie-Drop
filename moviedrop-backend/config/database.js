const { Pool } = require('pg');

// Database connection configuration
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Test database connection
pool.on('connect', () => {
  console.log('✅ Connected to PostgreSQL database');
});

pool.on('error', (err) => {
  console.error('❌ Database connection error:', err);
});

// Initialize database tables
async function initializeDatabase() {
  try {
    // Create users table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        email VARCHAR(255) UNIQUE NOT NULL,
        display_name VARCHAR(255) NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Create user_sessions table for JWT token management
    await pool.query(`
      CREATE TABLE IF NOT EXISTS user_sessions (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        token_hash VARCHAR(255) NOT NULL,
        expires_at TIMESTAMP NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Create user_movie_lists table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS user_movie_lists (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        movie_id INTEGER NOT NULL,
        movie_title VARCHAR(255),
        movie_poster VARCHAR(500),
        list_type VARCHAR(50) NOT NULL, -- 'watchlist', 'watched', 'favorites'
        rating INTEGER CHECK (rating >= 1 AND rating <= 5),
        review TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, movie_id, list_type)
      )
    `);

    // Create user_friends table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS user_friends (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        friend_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'accepted', 'blocked'
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, friend_id)
      )
    `);

    // Create group_lists table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS group_lists (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        description TEXT,
        created_by INTEGER REFERENCES users(id) ON DELETE CASCADE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Create group_list_members table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS group_list_members (
        id SERIAL PRIMARY KEY,
        group_id INTEGER REFERENCES group_lists(id) ON DELETE CASCADE,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        role VARCHAR(20) DEFAULT 'member', -- 'admin', 'member'
        joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(group_id, user_id)
      )
    `);

    // Create group_list_movies table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS group_list_movies (
        id SERIAL PRIMARY KEY,
        group_id INTEGER REFERENCES group_lists(id) ON DELETE CASCADE,
        movie_id INTEGER NOT NULL,
        added_by INTEGER REFERENCES users(id) ON DELETE CASCADE,
        rating INTEGER CHECK (rating >= 1 AND rating <= 5),
        review TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(group_id, movie_id)
      )
    `);

    // Create user_signals table for tracking user preferences
    await pool.query(`
      CREATE TABLE IF NOT EXISTS user_signals (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        movie_id INTEGER NOT NULL,
        action VARCHAR(50) NOT NULL, -- 'like', 'dismiss', 'share', 'watchlist'
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, movie_id, action)
      )
    `);

    // Create movies table for storing movie metadata
    await pool.query(`
      CREATE TABLE IF NOT EXISTS movies (
        id INTEGER PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        overview TEXT,
        poster_path VARCHAR(500),
        backdrop_path VARCHAR(500),
        release_date DATE,
        popularity DECIMAL(10,2),
        vote_average DECIMAL(3,1),
        vote_count INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Create genres table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS genres (
        id INTEGER PRIMARY KEY,
        name VARCHAR(100) NOT NULL UNIQUE
      )
    `);

    // Create movie_genres junction table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS movie_genres (
        movie_id INTEGER REFERENCES movies(id) ON DELETE CASCADE,
        genre_id INTEGER REFERENCES genres(id) ON DELETE CASCADE,
        PRIMARY KEY (movie_id, genre_id)
      )
    `);

    console.log('✅ Database tables initialized successfully');
  } catch (error) {
    console.error('❌ Error initializing database:', error);
    throw error;
  }
}

module.exports = { pool, initializeDatabase };
