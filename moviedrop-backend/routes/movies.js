const express = require('express');
const axios = require('axios');
const RottenTomatoesService = require('../services/rottenTomatoesService');
const { Pool } = require('pg');

const router = express.Router();
const rtService = new RottenTomatoesService();

// Function to enhance movie with RT data
async function enhanceMovieWithRTData(movie) {
  try {
    const releaseYear = movie.release_date ? new Date(movie.release_date).getFullYear() : null;
    const rtData = await rtService.getRottenTomatoesData(movie.title, releaseYear);
    
    return {
      ...movie,
      rotten_tomatoes_score: rtData?.tomatometer || null,
      community_reviews: rtData?.criticsConsensus ? [rtData.criticsConsensus] : []
    };
  } catch (error) {
    console.error(`Error enhancing movie ${movie.title} with RT data:`, error);
    return {
      ...movie,
      rotten_tomatoes_score: null,
      community_reviews: []
    };
  }
}

// Database connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});

// Get popular movies with randomization
router.get('/popular', async (req, res) => {
  try {
    const { page = 1, randomize = true } = req.query;
    const tmdbApiKey = process.env.TMDB_API_KEY;
    
    if (!tmdbApiKey) {
      console.log('❌ TMDB API key not configured');
      return res.status(500).json({ error: 'TMDB API key not configured' });
    }

    try {
      // Get multiple pages to have more movies to randomize from
      const pagesToFetch = randomize === 'true' ? [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] : [page]; // More pages for better variety
      const shuffledPages = randomize === 'true' ? pagesToFetch.sort(() => Math.random() - 0.5) : pagesToFetch; // Randomize page order
      const allMovies = [];
      
      for (const pageNum of shuffledPages) {
        try {
          const response = await axios.get(
            `https://api.themoviedb.org/3/movie/popular?api_key=${tmdbApiKey}&page=${pageNum}`,
            { timeout: 10000 } // 10 second timeout
          );
          if (response.data && response.data.results) {
            allMovies.push(...response.data.results);
            console.log(`✅ Fetched page ${pageNum}: ${response.data.results.length} movies`);
          }
        } catch (pageError) {
          console.log(`⚠️ Failed to fetch page ${pageNum}:`, pageError.message);
          // Continue with other pages
        }
      }

      // Check if we got enough movies from TMDB
      if (allMovies.length === 0) {
        console.log('❌ No movies fetched from TMDB');
        return res.status(500).json({ error: 'No movies fetched from TMDB' });
      }

      console.log(`✅ Successfully fetched ${allMovies.length} movies from TMDB`);

      // Randomize the movies if requested
      if (randomize === 'true') {
        // Use timestamp as seed for better randomization
        const seed = Date.now();
        const seededRandom = (seed) => {
          const x = Math.sin(seed) * 10000;
          return x - Math.floor(x);
        };
        
        for (let i = allMovies.length - 1; i > 0; i--) {
          const j = Math.floor(seededRandom(seed + i) * (i + 1));
          [allMovies[i], allMovies[j]] = [allMovies[j], allMovies[i]];
        }
      }

      // Enhance movies with RT data (limit to first 20 for performance)
      const moviesToEnhance = allMovies.slice(0, 20);
      const enhancedMovies = await Promise.all(
        moviesToEnhance.map(movie => enhanceMovieWithRTData(movie))
      );

      // Return the enhanced results
      res.json({
        page: 1,
        results: enhancedMovies,
        total_pages: 1,
        total_results: enhancedMovies.length
      });
    } catch (tmdbError) {
      console.log('❌ TMDB API error:', tmdbError.message);
      return res.status(500).json({ error: 'Failed to fetch movies from TMDB' });
    }
  } catch (error) {
    console.error('Error fetching popular movies:', error);
    res.status(500).json({ error: 'Failed to fetch popular movies' });
  }
});

// Search movies
router.get('/search', async (req, res) => {
  try {
    const { query, page = 1 } = req.query;
    const tmdbApiKey = process.env.TMDB_API_KEY;
    
    if (!tmdbApiKey) {
      return res.status(500).json({ error: 'TMDB API key not configured' });
    }

    if (!query) {
      return res.status(400).json({ error: 'Query parameter is required' });
    }

    const response = await axios.get(
      `https://api.themoviedb.org/3/search/movie?api_key=${tmdbApiKey}&query=${encodeURIComponent(query)}&page=${page}`
    );

    res.json(response.data);
  } catch (error) {
    console.error('Error searching movies:', error);
    res.status(500).json({ error: 'Failed to search movies' });
  }
});

// Get movie details with Rotten Tomatoes data
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const tmdbApiKey = process.env.TMDB_API_KEY;
    
    if (!tmdbApiKey) {
      return res.status(500).json({ error: 'TMDB API key not configured' });
    }

    // Get movie details from TMDB
    const response = await axios.get(
      `https://api.themoviedb.org/3/movie/${id}?api_key=${tmdbApiKey}`
    );

    const movie = response.data;
    
    // Get Rotten Tomatoes data
    const releaseYear = movie.release_date ? new Date(movie.release_date).getFullYear() : null;
    const rtData = await rtService.getRottenTomatoesData(movie.title, releaseYear);
    
    // Combine TMDB and RT data
    const enhancedMovie = {
      ...movie,
      rottenTomatoes: rtData
    };

    res.json(enhancedMovie);
  } catch (error) {
    console.error('Error fetching movie details:', error);
    res.status(500).json({ error: 'Failed to fetch movie details' });
  }
});

// Get Rotten Tomatoes data for a specific movie
router.get('/:id/rotten-tomatoes', async (req, res) => {
  try {
    const { id } = req.params;
    const tmdbApiKey = process.env.TMDB_API_KEY;
    
    if (!tmdbApiKey) {
      return res.status(500).json({ error: 'TMDB API key not configured' });
    }

    // Get movie title and year from TMDB
    const response = await axios.get(
      `https://api.themoviedb.org/3/movie/${id}?api_key=${tmdbApiKey}`
    );

    const movie = response.data;
    const releaseYear = movie.release_date ? new Date(movie.release_date).getFullYear() : null;
    
    // Get Rotten Tomatoes data
    const rtData = await rtService.getRottenTomatoesData(movie.title, releaseYear);
    
    res.json(rtData);
  } catch (error) {
    console.error('Error fetching Rotten Tomatoes data:', error);
    res.status(500).json({ error: 'Failed to fetch Rotten Tomatoes data' });
  }
});

// Add movie to user's watchlist
router.post('/watchlist', async (req, res) => {
  try {
    const { userId, movieId, movieTitle, moviePoster } = req.body;
    
    console.log('📝 Watchlist request:', { userId, movieId, movieTitle, moviePoster });
    
    if (!userId || !movieId) {
      return res.status(400).json({ error: 'userId and movieId are required' });
    }

    // Check if movie is already in watchlist
    const existingMovie = await pool.query(
      'SELECT * FROM user_movie_lists WHERE user_id = $1 AND movie_id = $2 AND list_type = $3',
      [userId, movieId, 'watchlist']
    );

    if (existingMovie.rows.length > 0) {
      return res.status(409).json({ error: 'Movie already in watchlist' });
    }

    // Add to watchlist
    const result = await pool.query(
      'INSERT INTO user_movie_lists (user_id, movie_id, movie_title, movie_poster, list_type, created_at) VALUES ($1, $2, $3, $4, $5, NOW())',
      [userId, movieId, movieTitle, moviePoster, 'watchlist']
    );

    console.log('✅ Movie added to watchlist:', result.rowCount);
    res.json({ message: 'Movie added to watchlist successfully' });
  } catch (error) {
    console.error('❌ Error adding movie to watchlist:', error);
    res.status(500).json({ error: 'Failed to add movie to watchlist' });
  }
});

// Get user's watchlist
router.get('/watchlist/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    const result = await pool.query(
      'SELECT * FROM user_movie_lists WHERE user_id = $1 AND list_type = $2 ORDER BY created_at DESC',
      [userId, 'watchlist']
    );

    res.json({ movies: result.rows });
  } catch (error) {
    console.error('Error fetching watchlist:', error);
    res.status(500).json({ error: 'Failed to fetch watchlist' });
  }
});

// Remove movie from user's watchlist
router.delete('/watchlist/:userId/:movieId', async (req, res) => {
  try {
    const { userId, movieId } = req.params;
    
    const result = await pool.query(
      'DELETE FROM user_movie_lists WHERE user_id = $1 AND movie_id = $2 AND list_type = $3',
      [userId, movieId, 'watchlist']
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Movie not found in watchlist' });
    }

    res.json({ message: 'Movie removed from watchlist successfully' });
  } catch (error) {
    console.error('Error removing movie from watchlist:', error);
    res.status(500).json({ error: 'Failed to remove movie from watchlist' });
  }
});

// Get personalized movie recommendations
router.get('/recommendations/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const { limit = 20 } = req.query;
    console.log('🎯 Getting recommendations for user:', userId);
    
    // Get user's liked movies from watchlist
    const likedMovies = await pool.query(
      'SELECT movie_id, movie_title FROM user_movie_lists WHERE user_id = $1 AND list_type = $2',
      [userId, 'watchlist']
    );
    
    if (likedMovies.rows.length === 0) {
      // If no liked movies, return popular movies
      console.log('📊 No liked movies found, returning popular movies');
      return res.redirect('/api/movies/popular?randomize=true');
    }
    
    // Get genres from liked movies
    const likedMovieIds = likedMovies.rows.map(m => m.movie_id);
    console.log('🎬 Liked movie IDs:', likedMovieIds);
    
    // For now, return popular movies with randomization
    // TODO: Implement actual recommendation algorithm based on genres, cast, etc.
    const tmdbApiKey = process.env.TMDB_API_KEY;
    
    if (!tmdbApiKey) {
      console.log('❌ TMDB API key not configured');
      return res.status(500).json({ error: 'TMDB API key not configured' });
    }
    
    // Get movies from multiple pages for variety - randomize page order
    const pagesToFetch = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]; // More pages for better variety
    const shuffledPages = pagesToFetch.sort(() => Math.random() - 0.5); // Randomize page order
    const allMovies = [];
    
    for (const pageNum of shuffledPages) {
      try {
        const response = await axios.get(
          `https://api.themoviedb.org/3/movie/popular?api_key=${tmdbApiKey}&page=${pageNum}`,
          { timeout: 10000 }
        );
        if (response.data && response.data.results) {
          allMovies.push(...response.data.results);
          console.log(`✅ Fetched page ${pageNum}: ${response.data.results.length} movies`);
        }
      } catch (pageError) {
        console.log(`⚠️ Failed to fetch page ${pageNum}:`, pageError.message);
      }
    }
    
    // Filter out already liked movies
    const filteredMovies = allMovies.filter(movie => !likedMovieIds.includes(movie.id));
    
    // Shuffle and limit results with better randomization
    const seed = Date.now();
    const seededRandom = (seed) => {
      const x = Math.sin(seed) * 10000;
      return x - Math.floor(x);
    };
    
    const shuffledMovies = filteredMovies.sort(() => seededRandom(seed + Math.random()) - 0.5);
    const recommendations = shuffledMovies.slice(0, parseInt(limit));
    
    console.log(`🎯 Generated ${recommendations.length} recommendations for user ${userId}`);
    
    res.json({
      page: 1,
      results: recommendations,
      total_pages: 1,
      total_results: recommendations.length,
      user_id: userId,
      based_on_likes: likedMovies.rows.length
    });
    
  } catch (error) {
    console.error('❌ Error getting recommendations:', error);
    res.status(500).json({ error: 'Failed to get recommendations' });
  }
});

module.exports = router;
