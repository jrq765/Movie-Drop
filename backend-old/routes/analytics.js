const express = require('express');
const router = express.Router();

// In-memory storage for demo - in production, use a proper database
const analyticsData = {
    clicks: [],
    shares: [],
    searches: [],
    movieCards: []
};

// Track movie card share
router.post('/share', async (req, res) => {
    try {
        const { movieId, shareId, platform, userId } = req.body;
        
        const shareEvent = {
            id: Date.now().toString(),
            movieId: parseInt(movieId),
            shareId,
            platform: platform || 'unknown',
            userId: userId || 'anonymous',
            timestamp: new Date().toISOString(),
            ip: req.ip,
            userAgent: req.get('User-Agent')
        };

        analyticsData.shares.push(shareEvent);
        
        console.log('Share tracked:', shareEvent);

        res.json({
            success: true,
            message: 'Share tracked successfully',
            shareId: shareEvent.id
        });

    } catch (error) {
        console.error('Share tracking error:', error);
        res.status(500).json({
            error: 'Failed to track share',
            message: error.message
        });
    }
});

// Track movie card click
router.post('/click', async (req, res) => {
    try {
        const { movieId, shareId, platform, action, userId } = req.body;
        
        const clickEvent = {
            id: Date.now().toString(),
            movieId: parseInt(movieId),
            shareId,
            platform: platform || 'unknown',
            action: action || 'view',
            userId: userId || 'anonymous',
            timestamp: new Date().toISOString(),
            ip: req.ip,
            userAgent: req.get('User-Agent')
        };

        analyticsData.clicks.push(clickEvent);
        
        console.log('Click tracked:', clickEvent);

        res.json({
            success: true,
            message: 'Click tracked successfully',
            clickId: clickEvent.id
        });

    } catch (error) {
        console.error('Click tracking error:', error);
        res.status(500).json({
            error: 'Failed to track click',
            message: error.message
        });
    }
});

// Track search query
router.post('/search', async (req, res) => {
    try {
        const { query, results, userId } = req.body;
        
        const searchEvent = {
            id: Date.now().toString(),
            query: query.trim(),
            resultsCount: results || 0,
            userId: userId || 'anonymous',
            timestamp: new Date().toISOString(),
            ip: req.ip,
            userAgent: req.get('User-Agent')
        };

        analyticsData.searches.push(searchEvent);
        
        console.log('Search tracked:', searchEvent);

        res.json({
            success: true,
            message: 'Search tracked successfully',
            searchId: searchEvent.id
        });

    } catch (error) {
        console.error('Search tracking error:', error);
        res.status(500).json({
            error: 'Failed to track search',
            message: error.message
        });
    }
});

// Track movie card creation
router.post('/movie-card', async (req, res) => {
    try {
        const { movieId, shareId, userId } = req.body;
        
        const cardEvent = {
            id: Date.now().toString(),
            movieId: parseInt(movieId),
            shareId,
            userId: userId || 'anonymous',
            timestamp: new Date().toISOString(),
            ip: req.ip,
            userAgent: req.get('User-Agent')
        };

        analyticsData.movieCards.push(cardEvent);
        
        console.log('Movie card creation tracked:', cardEvent);

        res.json({
            success: true,
            message: 'Movie card creation tracked successfully',
            cardId: cardEvent.id
        });

    } catch (error) {
        console.error('Movie card tracking error:', error);
        res.status(500).json({
            error: 'Failed to track movie card creation',
            message: error.message
        });
    }
});

// Get analytics summary (admin endpoint)
router.get('/summary', (req, res) => {
    try {
        const now = new Date();
        const last24Hours = new Date(now.getTime() - 24 * 60 * 60 * 1000);
        const last7Days = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
        const last30Days = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

        const filterByDate = (data, date) => 
            data.filter(item => new Date(item.timestamp) >= date);

        const summary = {
            total: {
                shares: analyticsData.shares.length,
                clicks: analyticsData.clicks.length,
                searches: analyticsData.searches.length,
                movieCards: analyticsData.movieCards.length
            },
            last24Hours: {
                shares: filterByDate(analyticsData.shares, last24Hours).length,
                clicks: filterByDate(analyticsData.clicks, last24Hours).length,
                searches: filterByDate(analyticsData.searches, last24Hours).length,
                movieCards: filterByDate(analyticsData.movieCards, last24Hours).length
            },
            last7Days: {
                shares: filterByDate(analyticsData.shares, last7Days).length,
                clicks: filterByDate(analyticsData.clicks, last7Days).length,
                searches: filterByDate(analyticsData.searches, last7Days).length,
                movieCards: filterByDate(analyticsData.movieCards, last7Days).length
            },
            last30Days: {
                shares: filterByDate(analyticsData.shares, last30Days).length,
                clicks: filterByDate(analyticsData.clicks, last30Days).length,
                searches: filterByDate(analyticsData.searches, last30Days).length,
                movieCards: filterByDate(analyticsData.movieCards, last30Days).length
            },
            topSearches: getTopSearches(),
            topMovies: getTopMovies(),
            platformBreakdown: getPlatformBreakdown()
        };

        res.json(summary);

    } catch (error) {
        console.error('Analytics summary error:', error);
        res.status(500).json({
            error: 'Failed to generate analytics summary',
            message: error.message
        });
    }
});

// Helper functions
function getTopSearches() {
    const searchCounts = {};
    analyticsData.searches.forEach(search => {
        const query = search.query.toLowerCase();
        searchCounts[query] = (searchCounts[query] || 0) + 1;
    });
    
    return Object.entries(searchCounts)
        .sort(([,a], [,b]) => b - a)
        .slice(0, 10)
        .map(([query, count]) => ({ query, count }));
}

function getTopMovies() {
    const movieCounts = {};
    analyticsData.shares.forEach(share => {
        movieCounts[share.movieId] = (movieCounts[share.movieId] || 0) + 1;
    });
    
    return Object.entries(movieCounts)
        .sort(([,a], [,b]) => b - a)
        .slice(0, 10)
        .map(([movieId, count]) => ({ movieId: parseInt(movieId), count }));
}

function getPlatformBreakdown() {
    const platformCounts = {};
    analyticsData.shares.forEach(share => {
        platformCounts[share.platform] = (platformCounts[share.platform] || 0) + 1;
    });
    
    return Object.entries(platformCounts)
        .map(([platform, count]) => ({ platform, count }));
}

module.exports = router;
