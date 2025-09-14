const express = require('express');
const axios = require('axios');
const RottenTomatoesService = require('../services/rottenTomatoesService');

const router = express.Router();
const rtService = new RottenTomatoesService();

// Get popular movies
router.get('/popular', async (req, res) => {
  try {
    const { page = 1 } = req.query;
    const tmdbApiKey = process.env.TMDB_API_KEY;
    
    if (!tmdbApiKey) {
      return res.status(500).json({ error: 'TMDB API key not configured' });
    }

    const response = await axios.get(
      `https://api.themoviedb.org/3/movie/popular?api_key=${tmdbApiKey}&page=${page}`
    );

    res.json(response.data);
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

module.exports = router;
