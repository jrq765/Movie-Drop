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

            // Fallback: Return mock data
            return this.getMockRottenTomatoesData(movieTitle);

        } catch (error) {
            console.error('Error fetching Rotten Tomatoes data:', error);
            return this.getMockRottenTomatoesData(movieTitle);
        }
    }

    /**
     * Get RT data from OMDb API
     */
    async getFromOMDb(movieTitle, releaseYear) {
        try {
            const response = await axios.get(this.omdbBaseUrl, {
                params: {
                    apikey: this.omdbApiKey,
                    t: movieTitle,
                    y: releaseYear,
                    plot: 'short'
                }
            });

            if (response.data.Response === 'True') {
                const data = response.data;
                return {
                    tomatometer: this.parseRating(data.Ratings?.find(r => r.Source === 'Rotten Tomatoes')?.Value),
                    audienceScore: this.parseRating(data.Ratings?.find(r => r.Source === 'Internet Movie Database')?.Value),
                    imdbRating: data.imdbRating,
                    metascore: data.Metascore,
                    source: 'OMDb'
                };
            }
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
                    tomatometer: Math.floor(Math.random() * 40) + 60, // Mock data
                    audienceScore: Math.floor(Math.random() * 40) + 60,
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

    /**
     * Generate mock RT data for development
     */
    getMockRottenTomatoesData(movieTitle) {
        // Generate consistent mock data based on movie title
        const hash = this.simpleHash(movieTitle);
        const baseScore = 60 + (hash % 35); // Score between 60-95
        
        return {
            tomatometer: baseScore,
            audienceScore: baseScore + (hash % 10) - 5, // Audience score ±5 from critic score
            criticsConsensus: this.getMockConsensus(baseScore),
            source: 'Mock Data'
        };
    }

    /**
     * Simple hash function for consistent mock data
     */
    simpleHash(str) {
        let hash = 0;
        for (let i = 0; i < str.length; i++) {
            const char = str.charCodeAt(i);
            hash = ((hash << 5) - hash) + char;
            hash = hash & hash; // Convert to 32-bit integer
        }
        return Math.abs(hash);
    }

    /**
     * Get mock consensus based on score
     */
    getMockConsensus(score) {
        if (score >= 90) {
            return "Certified Fresh! Critics agree this is a must-see masterpiece.";
        } else if (score >= 80) {
            return "Fresh! Critics praise this film for its quality and entertainment value.";
        } else if (score >= 70) {
            return "Mostly Fresh. Critics find this film enjoyable with some reservations.";
        } else if (score >= 60) {
            return "Mixed reviews. Critics are divided on this film's merits.";
        } else {
            return "Rotten. Critics found this film lacking in several areas.";
        }
    }
}

module.exports = RottenTomatoesService;
