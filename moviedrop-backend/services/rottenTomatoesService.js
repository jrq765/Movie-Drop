const axios = require('axios');

class RottenTomatoesService {
    constructor() {
        // Option 1: Official RT API (when approved)
        this.rtApiKey = process.env.ROTTEN_TOMATOES_API_KEY;
        this.rtBaseUrl = 'https://api.rottentomatoes.com/api/public/v1.0';
        
        // Option 2: Alternative API (OMDb has some RT data)
        this.omdbApiKey = process.env.OMDB_API_KEY;
        this.omdbBaseUrl = 'http://www.omdbapi.com';
        
        // Option 3: RapidAPI alternatives
        this.rapidApiKey = process.env.RAPIDAPI_KEY;
    }

    /**
     * Get Rotten Tomatoes data for a movie
     * @param {string} movieTitle - The movie title
     * @param {number} releaseYear - The release year
     * @returns {Object} Rotten Tomatoes data
     */
    async getRottenTomatoesData(movieTitle, releaseYear) {
        try {
            // Try multiple sources in order of preference
            let rtData = null;

            // Method 1: Try OMDb API (has some RT data)
            if (this.omdbApiKey) {
                rtData = await this.getFromOMDb(movieTitle, releaseYear);
                if (rtData) return rtData;
            }

            // Method 2: Try official RT API (if approved)
            if (this.rtApiKey) {
                rtData = await this.getFromRottenTomatoes(movieTitle, releaseYear);
                if (rtData) return rtData;
            }

            // Method 3: Try RapidAPI alternatives
            if (this.rapidApiKey) {
                rtData = await this.getFromRapidAPI(movieTitle, releaseYear);
                if (rtData) return rtData;
            }

            // No fallback - return null if no data found
            console.warn(`No Rotten Tomatoes data found for: ${movieTitle}`);
            return null;

        } catch (error) {
            console.error('Error fetching Rotten Tomatoes data:', error);
            return null;
        }
    }

    /**
     * Get RT data from OMDb API
     */
    async getFromOMDb(movieTitle, releaseYear) {
        try {
            console.log(`🔍 OMDb: Searching for "${movieTitle}" (${releaseYear})`);
            
            // Try multiple search strategies
            const searchStrategies = [
                { t: movieTitle, y: releaseYear },
                { t: movieTitle }, // Without year
                { t: movieTitle.replace(/[^\w\s]/g, '') }, // Remove special characters
                { t: movieTitle.split(' ')[0] } // Just first word
            ];
            
            for (const strategy of searchStrategies) {
                try {
                    const response = await axios.get(this.omdbBaseUrl, {
                        params: {
                            apikey: this.omdbApiKey,
                            ...strategy,
                            plot: 'short'
                        }
                    });

                    console.log(`📊 OMDb Response for "${strategy.t}":`, response.data.Response);
                    if (response.data.Response === 'True') {
                        const data = response.data;
                        const rtRating = data.Ratings?.find(r => r.Source === 'Rotten Tomatoes')?.Value;
                        const tomatometer = this.parseRating(rtRating);
                        
                        if (tomatometer !== null) {
                            console.log(`🍅 Rotten Tomatoes rating found: ${rtRating} -> ${tomatometer}%`);
                            
                            return {
                                tomatometer: tomatometer,
                                audienceScore: this.parseRating(data.Ratings?.find(r => r.Source === 'Internet Movie Database')?.Value),
                                imdbRating: data.imdbRating,
                                metascore: data.Metascore,
                                source: 'OMDb'
                            };
                        }
                    }
                } catch (strategyError) {
                    console.log(`⚠️ OMDb strategy failed for "${strategy.t}":`, strategyError.message);
                }
            }
            
            console.log(`❌ OMDb: No RT data found for "${movieTitle}"`);
        } catch (error) {
            console.error('OMDb API error:', error);
        }
        return null;
    }

    /**
     * Get RT data from official Rotten Tomatoes API
     */
    async getFromRottenTomatoes(movieTitle, releaseYear) {
        try {
            // Search for movie
            const searchResponse = await axios.get(`${this.rtBaseUrl}/movies.json`, {
                params: {
                    apikey: this.rtApiKey,
                    q: movieTitle,
                    page_limit: 1
                }
            });

            if (searchResponse.data.movies && searchResponse.data.movies.length > 0) {
                const movie = searchResponse.data.movies[0];
                
                // Get detailed movie info
                const detailResponse = await axios.get(`${this.rtBaseUrl}/movies/${movie.id}.json`, {
                    params: {
                        apikey: this.rtApiKey
                    }
                });

                return {
                    tomatometer: detailResponse.data.ratings.critics_score,
                    audienceScore: detailResponse.data.ratings.audience_score,
                    criticsConsensus: detailResponse.data.critics_consensus,
                    source: 'Rotten Tomatoes'
                };
            }
        } catch (error) {
            console.error('Rotten Tomatoes API error:', error);
        }
        return null;
    }

    /**
     * Get RT data from RapidAPI alternatives
     */
    async getFromRapidAPI(movieTitle, releaseYear) {
        try {
            // Example using a RapidAPI service (you'd need to find a specific one)
            const response = await axios.get('https://movie-database-alternative.p.rapidapi.com/', {
                params: {
                    s: movieTitle,
                    y: releaseYear
                },
                headers: {
                    'X-RapidAPI-Key': this.rapidApiKey,
                    'X-RapidAPI-Host': 'movie-database-alternative.p.rapidapi.com'
                }
            });

            if (response.data.Search && response.data.Search.length > 0) {
                const movie = response.data.Search[0];
                return {
                    tomatometer: null, // No RT data available
                    audienceScore: null,
                    source: 'RapidAPI'
                };
            }
        } catch (error) {
            console.error('RapidAPI error:', error);
        }
        return null;
    }

    /**
     * Parse rating string to number
     */
    parseRating(ratingString) {
        if (!ratingString) return null;
        
        // Handle "85%" format
        if (ratingString.includes('%')) {
            return parseInt(ratingString.replace('%', ''));
        }
        
        // Handle "8.5/10" format
        if (ratingString.includes('/')) {
            const [score, total] = ratingString.split('/');
            return Math.round((parseFloat(score) / parseFloat(total)) * 100);
        }
        
        // Handle "8.5" format (assume out of 10)
        const score = parseFloat(ratingString);
        if (!isNaN(score)) {
            return Math.round(score * 10);
        }
        
        return null;
    }

}

module.exports = RottenTomatoesService;
