const express = require('express');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 3000;

// Serve static files
app.use(express.static(path.join(__dirname)));

// Handle dynamic movie routes
app.get('/m/:movieId', (req, res) => {
    const movieId = req.params.movieId;
    const region = req.query.region || 'US';
    
    // Serve the main HTML file with the movie ID in the URL
    res.sendFile(path.join(__dirname, 'index.html'));
});

// Handle root route
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

// Start server
app.listen(PORT, () => {
    console.log(`🎬 MovieDrop web server running on port ${PORT}`);
    console.log(`📱 Access your branded landing pages at: http://localhost:${PORT}/m/{movieId}?region={region}`);
});
