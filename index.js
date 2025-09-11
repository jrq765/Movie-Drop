const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
require('dotenv').config();

const movieRoutes = require('./backend/routes/movies');
const streamingRoutes = require('./backend/routes/streaming');
const analyticsRoutes = require('./backend/routes/analytics');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(compression());
app.use(morgan('combined'));
app.use(cors({
    origin: process.env.ALLOWED_ORIGINS?.split(',') || [
        'http://localhost:3000', 
        'https://moviedrop.app',
        'http://192.168.0.31:3000',
        'http://127.0.0.1:3000'
    ],
    credentials: true
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api/movies', movieRoutes);
app.use('/api/streaming', streamingRoutes);
app.use('/api/analytics', analyticsRoutes);

// Movie page route for universal links
app.get('/m/:id', async (req, res) => {
    try {
        const movieId = req.params.id;
        const region = req.query.region || process.env.REGION_DEFAULT || 'US';
        
        // Fetch movie data from TMDB
        const movieResponse = await fetch(`https://api.themoviedb.org/3/movie/${movieId}?api_key=${process.env.TMDB_API_KEY}`);
        if (!movieResponse.ok) {
            return res.status(404).send(`
                <!DOCTYPE html>
                <html>
                <head>
                    <title>Movie Not Found - MovieDrop</title>
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <style>
                        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; text-align: center; padding: 50px; }
                        h1 { color: #333; }
                        .logo { font-size: 2em; margin-bottom: 20px; }
                    </style>
                </head>
                <body>
                    <div class="logo">🎬</div>
                    <h1>Movie Not Found</h1>
                    <p>The movie you're looking for doesn't exist.</p>
                </body>
                </html>
            `);
        }
        
        const movie = await movieResponse.json();
        
        // Fetch watch providers
        let watchProviders = null;
        try {
            const providersResponse = await fetch(`https://api.themoviedb.org/3/movie/${movieId}/watch/providers?api_key=${process.env.TMDB_API_KEY}`);
            if (providersResponse.ok) {
                const providersData = await providersResponse.json();
                watchProviders = providersData.results[region] || null;
            }
        } catch (error) {
            console.error('Error fetching watch providers:', error);
        }
        
        const releaseYear = new Date(movie.release_date).getFullYear();
        const runtime = movie.runtime ? `${Math.floor(movie.runtime / 60)}h ${movie.runtime % 60}m` : null;
        
        res.send(`
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>${movie.title} (${releaseYear}) - MovieDrop</title>
                <meta name="description" content="${movie.overview || `Watch ${movie.title} on your favorite streaming platform`}">
                <meta property="og:title" content="${movie.title} (${releaseYear})">
                <meta property="og:description" content="${movie.overview || `Watch ${movie.title} on your favorite streaming platform`}">
                <meta property="og:image" content="${movie.poster_path ? `https://image.tmdb.org/t/p/w780${movie.poster_path}` : 'https://moviedrop.app/og-image.jpg'}">
                <meta property="og:url" content="https://moviedrop.app/m/${movieId}">
                <style>
                    * { margin: 0; padding: 0; box-sizing: border-box; }
                    body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; background: #f9fafb; }
                    .container { max-width: 920px; margin: 0 auto; padding: 20px; }
                    .movie-card { background: white; border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); overflow: hidden; }
                    .movie-content { display: flex; flex-direction: column; }
                    @media (min-width: 768px) { .movie-content { flex-direction: row; } }
                    .poster { width: 100%; max-width: 300px; }
                    @media (min-width: 768px) { .poster { width: 300px; } }
                    .poster img { width: 100%; height: auto; }
                    .poster-placeholder { width: 100%; height: 400px; background: #e5e7eb; display: flex; align-items: center; justify-content: center; font-size: 4em; }
                    .info { padding: 24px; flex: 1; }
                    .title { font-size: 2em; font-weight: bold; color: #111827; margin-bottom: 8px; }
                    .meta { color: #6b7280; margin-bottom: 16px; }
                    .overview { color: #374151; line-height: 1.6; margin-bottom: 24px; }
                    .providers h3 { font-size: 1.25em; font-weight: 600; color: #111827; margin-bottom: 16px; }
                    .provider-list { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 16px; }
                    .provider { display: inline-flex; align-items: center; gap: 8px; padding: 8px 12px; border-radius: 8px; text-decoration: none; font-size: 0.875em; font-weight: 500; }
                    .provider.streaming { background: #dbeafe; color: #1e40af; }
                    .provider.rent { background: #dcfce7; color: #166534; }
                    .provider.buy { background: #f3e8ff; color: #7c3aed; }
                    .provider:hover { opacity: 0.8; }
                    .footer { background: white; border-top: 1px solid #e5e7eb; margin-top: 48px; padding: 24px; }
                    .footer-content { display: flex; justify-content: space-between; align-items: center; }
                    .logo { display: flex; align-items: center; gap: 8px; font-weight: 600; color: #111827; }
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="movie-card">
                        <div class="movie-content">
                            <div class="poster">
                                ${movie.poster_path ? 
                                    `<img src="https://image.tmdb.org/t/p/w780${movie.poster_path}" alt="${movie.title}" />` :
                                    `<div class="poster-placeholder">🎬</div>`
                                }
                            </div>
                            <div class="info">
                                <h1 class="title">${movie.title}</h1>
                                <div class="meta">
                                    ${releaseYear}
                                    ${runtime ? ` • ${runtime}` : ''}
                                    ${movie.vote_average > 0 ? ` • ⭐ ${movie.vote_average.toFixed(1)}/10` : ''}
                                </div>
                                ${movie.overview ? `<p class="overview">${movie.overview}</p>` : ''}
                                
                                <div class="providers">
                                    <h3>Where to Watch</h3>
                                    ${watchProviders ? `
                                        ${watchProviders.flatrate && watchProviders.flatrate.length > 0 ? `
                                            <div class="provider-list">
                                                ${watchProviders.flatrate.map(provider => `
                                                    <a href="https://www.justwatch.com/us/movie/${movieId}" target="_blank" class="provider streaming">
                                                        ${provider.logo_path ? `<img src="https://image.tmdb.org/t/p/w45${provider.logo_path}" alt="${provider.provider_name}" width="20" height="20" />` : ''}
                                                        ${provider.provider_name}
                                                    </a>
                                                `).join('')}
                                            </div>
                                        ` : ''}
                                        ${watchProviders.rent && watchProviders.rent.length > 0 ? `
                                            <div class="provider-list">
                                                ${watchProviders.rent.map(provider => `
                                                    <a href="https://www.justwatch.com/us/movie/${movieId}" target="_blank" class="provider rent">
                                                        ${provider.logo_path ? `<img src="https://image.tmdb.org/t/p/w45${provider.logo_path}" alt="${provider.provider_name}" width="20" height="20" />` : ''}
                                                        ${provider.provider_name}
                                                    </a>
                                                `).join('')}
                                            </div>
                                        ` : ''}
                                        ${watchProviders.buy && watchProviders.buy.length > 0 ? `
                                            <div class="provider-list">
                                                ${watchProviders.buy.map(provider => `
                                                    <a href="https://www.justwatch.com/us/movie/${movieId}" target="_blank" class="provider buy">
                                                        ${provider.logo_path ? `<img src="https://image.tmdb.org/t/p/w45${provider.logo_path}" alt="${provider.provider_name}" width="20" height="20" />` : ''}
                                                        ${provider.provider_name}
                                                    </a>
                                                `).join('')}
                                            </div>
                                        ` : ''}
                                    ` : '<p style="color: #6b7280;">Streaming availability information is not available for this movie.</p>'}
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <div class="footer">
                        <div class="footer-content">
                            <div class="logo">
                                <span>🎬</span>
                                <span>MovieDrop</span>
                            </div>
                        </div>
                    </div>
                </div>
            </body>
            </html>
        `);
    } catch (error) {
        console.error('Error rendering movie page:', error);
        res.status(500).send(`
            <!DOCTYPE html>
            <html>
            <head>
                <title>Error - MovieDrop</title>
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                    body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; text-align: center; padding: 50px; }
                    h1 { color: #333; }
                    .logo { font-size: 2em; margin-bottom: 20px; }
                </style>
            </head>
            <body>
                <div class="logo">🎬</div>
                <h1>Something went wrong</h1>
                <p>We couldn't load the movie information. Please try again later.</p>
            </body>
            </html>
        `);
    }
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ 
        status: 'healthy', 
        timestamp: new Date().toISOString(),
        version: process.env.npm_package_version || '1.0.0'
    });
});

// Root endpoint
app.get('/', (req, res) => {
    res.json({
        message: 'MovieDrop API',
        version: '1.0.0',
        endpoints: {
            movies: '/api/movies',
            streaming: '/api/streaming',
            analytics: '/api/analytics'
        }
    });
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error('Error:', err);
    
    if (err.type === 'entity.parse.failed') {
        return res.status(400).json({
            error: 'Invalid JSON',
            message: 'Request body contains invalid JSON'
        });
    }
    
    res.status(err.status || 500).json({
        error: err.message || 'Internal Server Error',
        ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
    });
});

// 404 handler
app.use('*', (req, res) => {
    res.status(404).json({
        error: 'Not Found',
        message: `Route ${req.originalUrl} not found`
    });
});

// Start server
app.listen(PORT, () => {
    console.log(`🚀 MovieDrop API server running on port ${PORT}`);
    console.log(`📱 Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`🔗 Health check: http://localhost:${PORT}/health`);
});

module.exports = app;
