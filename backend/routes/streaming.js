const express = require('express');
const axios = require('axios');
const router = express.Router();

// Mock streaming data - in production, integrate with JustWatch API or similar
const MOCK_STREAMING_DATA = {
    // Netflix
    'netflix': {
        name: 'Netflix',
        logo: 'https://upload.wikimedia.org/wikipedia/commons/0/08/Netflix_2015_logo.svg',
        affiliateUrl: 'https://netflix.com',
        type: 'subscription'
    },
    // Amazon Prime Video
    'amazon': {
        name: 'Amazon Prime Video',
        logo: 'https://upload.wikimedia.org/wikipedia/commons/1/11/Amazon_Prime_Video_logo.svg',
        affiliateUrl: 'https://amazon.com',
        type: 'subscription'
    },
    // Apple TV
    'apple': {
        name: 'Apple TV',
        logo: 'https://upload.wikimedia.org/wikipedia/commons/4/4e/Apple_TV_Plus_logo.svg',
        affiliateUrl: 'https://tv.apple.com',
        type: 'rent'
    },
    // YouTube Movies
    'youtube': {
        name: 'YouTube Movies',
        logo: 'https://upload.wikimedia.org/wikipedia/commons/0/09/YouTube_full-color_icon_%282017%29.svg',
        affiliateUrl: 'https://youtube.com',
        type: 'rent'
    },
    // Hulu
    'hulu': {
        name: 'Hulu',
        logo: 'https://upload.wikimedia.org/wikipedia/commons/e/e4/Hulu_Logo.svg',
        affiliateUrl: 'https://hulu.com',
        type: 'subscription'
    },
    // Disney+
    'disney': {
        name: 'Disney+',
        logo: 'https://upload.wikimedia.org/wikipedia/commons/7/77/Disney_Plus_logo.svg',
        affiliateUrl: 'https://disneyplus.com',
        type: 'subscription'
    }
};

// Get supported streaming platforms
router.get('/platforms', (req, res) => {
    try {
        const platforms = Object.values(MOCK_STREAMING_DATA).map(platform => ({
            id: Object.keys(MOCK_STREAMING_DATA).find(key => MOCK_STREAMING_DATA[key] === platform),
            name: platform.name,
            logo: platform.logo,
            type: platform.type
        }));

        res.json({
            platforms,
            totalCount: platforms.length
        });

    } catch (error) {
        console.error('Platforms error:', error);
        res.status(500).json({
            error: 'Failed to fetch platforms',
            message: error.message
        });
    }
});

// Get streaming availability for a movie
router.get('/:movieId', async (req, res) => {
    try {
        const { movieId } = req.params;
        
        if (!movieId || isNaN(movieId)) {
            return res.status(400).json({
                error: 'Valid movie ID is required'
            });
        }

        // In production, this would query JustWatch API or similar service
        // For now, return mock data based on movie ID
        const streamingOptions = getMockStreamingOptions(movieId);

        res.json({
            movieId: parseInt(movieId),
            streamingOptions,
            lastUpdated: new Date().toISOString()
        });

    } catch (error) {
        console.error('Streaming availability error:', error);
        res.status(500).json({
            error: 'Failed to fetch streaming availability',
            message: error.message
        });
    }
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

        const results = movieIds.map(movieId => ({
            movieId: parseInt(movieId),
            streamingOptions: getMockStreamingOptions(movieId),
            lastUpdated: new Date().toISOString()
        }));

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

// Helper function to generate mock streaming options
function getMockStreamingOptions(movieId) {
    const platforms = Object.keys(MOCK_STREAMING_DATA);
    const numOptions = Math.floor(Math.random() * 4) + 2; // 2-5 options
    const selectedPlatforms = platforms.sort(() => 0.5 - Math.random()).slice(0, numOptions);
    
    return selectedPlatforms.map(platformKey => {
        const platform = MOCK_STREAMING_DATA[platformKey];
        const isRentOrBuy = platform.type === 'rent' || platform.type === 'buy';
        
        return {
            platform: platform.name,
            platformId: platformKey,
            type: platform.type,
            url: platform.affiliateUrl,
            price: isRentOrBuy ? getRandomPrice() : null,
            logo: platform.logo,
            available: true
        };
    });
}

// Helper function to generate random prices
function getRandomPrice() {
    const prices = ['$2.99', '$3.99', '$4.99', '$5.99', '$9.99', '$14.99', '$19.99'];
    return prices[Math.floor(Math.random() * prices.length)];
}

module.exports = router;
