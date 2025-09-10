const express = require('express');
const axios = require('axios');
const { v4: uuidv4 } = require('uuid');
const router = express.Router();

const TMDB_API_KEY = process.env.TMDB_API_KEY;
const TMDB_BASE_URL = 'https://api.themoviedb.org/3';
const MOVIEDROP_BASE_URL = process.env.MOVIEDROP_BASE_URL || 'https://moviedrop.app';

// Search movies
router.get('/search', async (req, res) => {
    try {
        const { query, page = 1 } = req.query;
        
        if (!query || query.trim().length === 0) {
            return res.status(400).json({
                error: 'Query parameter is required'
            });
        }

        const response = await axios.get(`${TMDB_BASE_URL}/search/movie`, {
            params: {
                api_key: TMDB_API_KEY,
                query: query.trim(),
                page: parseInt(page),
                include_adult: false,
                language: 'en-US'
            }
        });

        const movies = response.data.results.map(movie => ({
            id: movie.id,
            title: movie.title,
            overview: movie.overview,
            posterPath: movie.poster_path,
            backdropPath: movie.backdrop_path,
            releaseDate: movie.release_date,
            voteAverage: movie.vote_average,
            voteCount: movie.vote_count,
            adult: movie.adult,
            genreIds: movie.genre_ids,
            originalLanguage: movie.original_language,
            originalTitle: movie.original_title,
            popularity: movie.popularity,
            video: movie.video
        }));

        res.json({
            movies,
            page: response.data.page,
            totalPages: response.data.total_pages,
            totalResults: response.data.total_results
        });

    } catch (error) {
        console.error('Movie search error:', error);
        
        if (error.response?.status === 401) {
            return res.status(500).json({
                error: 'TMDB API key is invalid'
            });
        }
        
        res.status(500).json({
            error: 'Failed to search movies',
            message: error.message
        });
    }
});

// Get movie details
router.get('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        
        if (!id || isNaN(id)) {
            return res.status(400).json({
                error: 'Valid movie ID is required'
            });
        }

        const response = await axios.get(`${TMDB_BASE_URL}/movie/${id}`, {
            params: {
                api_key: TMDB_API_KEY,
                language: 'en-US',
                append_to_response: 'videos,credits'
            }
        });

        const movie = {
            id: response.data.id,
            title: response.data.title,
            overview: response.data.overview,
            posterPath: response.data.poster_path,
            backdropPath: response.data.backdrop_path,
            releaseDate: response.data.release_date,
            voteAverage: response.data.vote_average,
            runtime: response.data.runtime,
            genres: response.data.genres,
            videos: response.data.videos?.results || [],
            credits: response.data.credits
        };

        res.json(movie);

    } catch (error) {
        console.error('Movie details error:', error);
        
        if (error.response?.status === 404) {
            return res.status(404).json({
                error: 'Movie not found'
            });
        }
        
        res.status(500).json({
            error: 'Failed to fetch movie details',
            message: error.message
        });
    }
});

// Create movie card
router.post('/:id/card', async (req, res) => {
    try {
        const { id } = req.params;
        
        if (!id || isNaN(id)) {
            return res.status(400).json({
                error: 'Valid movie ID is required'
            });
        }

        // Get movie details
        const movieResponse = await axios.get(`${TMDB_BASE_URL}/movie/${id}`, {
            params: {
                api_key: TMDB_API_KEY,
                language: 'en-US'
            }
        });

        const movie = {
            id: movieResponse.data.id,
            title: movieResponse.data.title,
            overview: movieResponse.data.overview,
            posterPath: movieResponse.data.poster_path,
            backdropPath: movieResponse.data.backdrop_path,
            releaseDate: movieResponse.data.release_date,
            voteAverage: movieResponse.data.vote_average,
            runtime: movieResponse.data.runtime,
            genres: movieResponse.data.genres
        };

        // Generate unique share URL
        const shareId = uuidv4();
        const shareURL = `${MOVIEDROP_BASE_URL}/movie/${id}?share=${shareId}`;

        // Create movie card
        const movieCard = {
            id: shareId,
            movie,
            shareURL,
            createdAt: new Date().toISOString(),
            // Streaming info will be added by the streaming service
            streamingInfo: []
        };

        // Store movie card (in production, save to database)
        // For now, we'll return it directly
        res.json(movieCard);

    } catch (error) {
        console.error('Create movie card error:', error);
        
        if (error.response?.status === 404) {
            return res.status(404).json({
                error: 'Movie not found'
            });
        }
        
        res.status(500).json({
            error: 'Failed to create movie card',
            message: error.message
        });
    }
});

// Get popular movies
router.get('/popular', async (req, res) => {
    try {
        const { page = 1 } = req.query;

        const response = await axios.get(`${TMDB_BASE_URL}/movie/popular`, {
            params: {
                api_key: TMDB_API_KEY,
                page: parseInt(page),
                language: 'en-US'
            }
        });

        const movies = response.data.results.map(movie => ({
            id: movie.id,
            title: movie.title,
            overview: movie.overview,
            posterPath: movie.poster_path,
            backdropPath: movie.backdrop_path,
            releaseDate: movie.release_date,
            voteAverage: movie.vote_average,
            voteCount: movie.vote_count,
            adult: movie.adult,
            genreIds: movie.genre_ids,
            originalLanguage: movie.original_language,
            originalTitle: movie.original_title,
            popularity: movie.popularity,
            video: movie.video
        }));

        res.json({
            movies,
            page: response.data.page,
            totalPages: response.data.total_pages,
            totalResults: response.data.total_results
        });

    } catch (error) {
        console.error('Popular movies error:', error);
        res.status(500).json({
            error: 'Failed to fetch popular movies',
            message: error.message
        });
    }
});

// Get trending movies
router.get('/trending', async (req, res) => {
    try {
        const { timeWindow = 'week', page = 1 } = req.query;

        const response = await axios.get(`${TMDB_BASE_URL}/trending/movie/${timeWindow}`, {
            params: {
                api_key: TMDB_API_KEY,
                page: parseInt(page),
                language: 'en-US'
            }
        });

        const movies = response.data.results.map(movie => ({
            id: movie.id,
            title: movie.title,
            overview: movie.overview,
            posterPath: movie.poster_path,
            backdropPath: movie.backdrop_path,
            releaseDate: movie.release_date,
            voteAverage: movie.vote_average,
            voteCount: movie.vote_count,
            adult: movie.adult,
            genreIds: movie.genre_ids,
            originalLanguage: movie.original_language,
            originalTitle: movie.original_title,
            popularity: movie.popularity,
            video: movie.video
        }));

        res.json({
            movies,
            page: response.data.page,
            totalPages: response.data.total_pages,
            totalResults: response.data.total_results
        });

    } catch (error) {
        console.error('Trending movies error:', error);
        res.status(500).json({
            error: 'Failed to fetch trending movies',
            message: error.message
        });
    }
});

module.exports = router;
