const express = require('express');
const axios = require('axios');
const router = express.Router();
const { resolveProviderLink, getProviderInfo } = require('./linkResolver');

// Get streaming availability for a movie
router.get('/:movieId', async (req, res) => {
    try {
        const { movieId } = req.params;
        const region = req.query.region || process.env.REGION_DEFAULT || 'US';
        
        if (!movieId || isNaN(movieId)) {
            return res.status(400).json({
                error: 'Valid movie ID is required'
            });
        }

        // Check if TMDB API key is configured
        const tmdbApiKey = process.env.TMDB_API_KEY;
        if (!tmdbApiKey || tmdbApiKey === 'your_tmdb_api_key_here') {
            return res.status(500).json({
                error: 'TMDB API key not configured',
                message: 'Please set TMDB_API_KEY in your environment variables',
                restorationChecklist: [
                    '1. Get TMDB API key from https://www.themoviedb.org/settings/api',
                    '2. Add TMDB_API_KEY=your_actual_key to backend/.env',
                    '3. Restart the backend server'
                ]
            });
        }

        // Fetch movie details and watch providers from TMDB
        const [movieResponse, providersResponse] = await Promise.all([
            axios.get(`https://api.themoviedb.org/3/movie/${movieId}`, {
                params: { api_key: tmdbApiKey }
            }),
            axios.get(`https://api.themoviedb.org/3/movie/${movieId}/watch/providers`, {
                params: { api_key: tmdbApiKey }
            })
        ]);

        const movie = movieResponse.data;
        const providers = providersResponse.data;

        // Extract region-specific providers
        const regionProviders = providers.results[region];
        if (!regionProviders) {
            return res.json({
                region,
                movieId: parseInt(movieId),
                movieTitle: movie.title,
                movieYear: movie.release_date ? new Date(movie.release_date).getFullYear() : null,
                link: null,
                providers: [],
                message: `No streaming providers found for region: ${region}`
            });
        }

        // Build available providers array
        const availableProviders = [];
        const providerTypes = [
            { array: regionProviders.flatrate, kind: 'flatrate' },
            { array: regionProviders.buy, kind: 'buy' },
            { array: regionProviders.rent, kind: 'rent' }
        ];

        for (const type of providerTypes) {
            if (type.array) {
                for (const provider of type.array) {
                    // Check if provider already exists (deduplicate)
                    const existingIndex = availableProviders.findIndex(p => p.id === provider.provider_id);
                    if (existingIndex >= 0) {
                        // Update existing provider to include multiple types
                        if (!availableProviders[existingIndex].kinds.includes(type.kind)) {
                            availableProviders[existingIndex].kinds.push(type.kind);
                        }
                    } else {
                        // Resolve direct provider link
                        const directUrl = await resolveProviderLink({
                            title: movie.title,
                            year: movie.release_date ? new Date(movie.release_date).getFullYear() : null,
                            tmdbId: movieId,
                            region: region,
                            providerId: provider.provider_id
                        });

                        // Get provider info
                        const providerInfo = getProviderInfo(provider.provider_id);

                        availableProviders.push({
                            id: provider.provider_id,
                            name: provider.provider_name,
                            logo_path: provider.logo_path,
                            kinds: [type.kind],
                            url: directUrl || regionProviders.link, // Fallback to TMDB region page
                            isDirectLink: !!directUrl
                        });
                    }
                }
            }
        }

        res.json({
            region,
            movieId: parseInt(movieId),
            movieTitle: movie.title,
            movieYear: movie.release_date ? new Date(movie.release_date).getFullYear() : null,
            link: regionProviders.link, // TMDB/JustWatch region page fallback
            providers: availableProviders,
            lastUpdated: new Date().toISOString()
        });

    } catch (error) {
        console.error('Streaming availability error:', error);
        
        if (error.response?.status === 401) {
            return res.status(500).json({
                error: 'TMDB API authentication failed',
                message: 'Invalid TMDB API key',
                restorationChecklist: [
                    '1. Verify TMDB_API_KEY is correct in backend/.env',
                    '2. Check if API key has proper permissions',
                    '3. Restart the backend server'
                ]
            });
        }
        
        if (error.response?.status === 404) {
            return res.status(404).json({
                error: 'Movie not found',
                message: `Movie with ID ${req.params.movieId} not found in TMDB`
            });
        }

        res.status(500).json({
            error: 'Failed to fetch streaming availability',
            message: error.message
        });
    }
});

// Get supported streaming platforms (deprecated - use real data from TMDB)
router.get('/platforms', (req, res) => {
    res.json({
        platforms: [],
        totalCount: 0,
        message: 'Use /api/streaming/:movieId for real provider data from TMDB'
    });
});

// Get streaming options for multiple movies
router.post('/batch', async (req, res) => {
    try {
        const { movieIds } = req.body;
        
        if (!Array.isArray(movieIds) || movieIds.length === 0) {
            return res.status(400).json({
                error: 'Array of movie IDs is required'
            });
        }

        if (movieIds.length > 20) {
            return res.status(400).json({
                error: 'Maximum 20 movie IDs allowed per request'
            });
        }

        // Process each movie ID
        const results = await Promise.all(
            movieIds.map(async (movieId) => {
                try {
                    // Make internal request to single movie endpoint
                    const response = await axios.get(`http://localhost:${process.env.PORT || 3000}/api/streaming/${movieId}`);
                    return response.data;
                } catch (error) {
                    return {
                        movieId: parseInt(movieId),
                        error: error.response?.data?.error || 'Failed to fetch data',
                        providers: []
                    };
                }
            })
        );

        res.json({
            results,
            totalCount: results.length
        });

    } catch (error) {
        console.error('Batch streaming availability error:', error);
        res.status(500).json({
            error: 'Failed to fetch batch streaming availability',
            message: error.message
        });
    }
});

// Track streaming click (for affiliate tracking)
router.post('/click', async (req, res) => {
    try {
        const { movieId, platform, url, userAgent, ip } = req.body;
        
        // Log the click for affiliate tracking
        console.log('Streaming click tracked:', {
            movieId,
            platform,
            url,
            userAgent,
            ip: ip || req.ip,
            timestamp: new Date().toISOString()
        });

        // In production, save to database and track for affiliate commissions
        // For now, just return success
        res.json({
            success: true,
            message: 'Click tracked successfully',
            timestamp: new Date().toISOString()
        });

    } catch (error) {
        console.error('Click tracking error:', error);
        res.status(500).json({
            error: 'Failed to track click',
            message: error.message
        });
    }
});

module.exports = router;