const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const axios = require('axios');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use(limiter);

// CORS configuration
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  credentials: true
}));

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// Movie search endpoint
app.get('/api/movies/search', async (req, res) => {
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

// Get movie details
app.get('/api/movies/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const tmdbApiKey = process.env.TMDB_API_KEY;
    
    if (!tmdbApiKey) {
      return res.status(500).json({ error: 'TMDB API key not configured' });
    }

    const response = await axios.get(
      `https://api.themoviedb.org/3/movie/${id}?api_key=${tmdbApiKey}`
    );

    res.json(response.data);
  } catch (error) {
    console.error('Error fetching movie details:', error);
    res.status(500).json({ error: 'Failed to fetch movie details' });
  }
});

// Get popular movies
app.get('/api/movies/popular', async (req, res) => {
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

// Get streaming providers for a movie
app.get('/api/streaming/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { region = 'US' } = req.query;
    const tmdbApiKey = process.env.TMDB_API_KEY;
    
    if (!tmdbApiKey) {
      return res.status(500).json({ error: 'TMDB API key not configured' });
    }

    const response = await axios.get(
      `https://api.themoviedb.org/3/movie/${id}/watch/providers?api_key=${tmdbApiKey}`
    );

    const providers = response.data.results[region] || {};
    
    // Process and clean up the providers data
    const processedProviders = {
      flatrate: providers.flatrate || [],
      rent: providers.rent || [],
      buy: providers.buy || []
    };

    res.json(processedProviders);

  } catch (error) {
    console.error('Error fetching streaming providers:', error);
    res.status(500).json({ error: 'Failed to fetch streaming providers' });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({ 
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 MovieDrop Backend running on port ${PORT}`);
  console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🔗 Health check: http://localhost:${PORT}/health`);
  console.log(`🌐 Network access: http://0.0.0.0:${PORT}/health`);
});

module.exports = app;
