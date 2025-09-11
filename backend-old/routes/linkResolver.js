const axios = require('axios');

/**
 * Resolves direct provider links for movies
 * @param {Object} params - { title, year, tmdbId, region, providerId }
 * @returns {Promise<string|null>} - Direct provider URL or null
 */
async function resolveProviderLink({ title, year, tmdbId, region, providerId }) {
    try {
        // Provider-specific link resolution strategies
        const strategies = {
            // Apple TV+ (provider_id: 2)
            2: async () => {
                const searchTerm = encodeURIComponent(`${title} ${year} movie`);
                return `https://tv.apple.com/search?term=${searchTerm}`;
            },
            
            // Amazon Prime Video (provider_id: 9)
            9: async () => {
                const searchTerm = encodeURIComponent(`${title} ${year}`);
                return `https://www.amazon.com/s?k=${searchTerm}&i=instant-video`;
            },
            
            // Netflix (provider_id: 8)
            8: async () => {
                // Netflix doesn't have direct movie links, return null to use fallback
                return null;
            },
            
            // YouTube Movies (provider_id: 192)
            192: async () => {
                const searchTerm = encodeURIComponent(`${title} ${year} movie`);
                return `https://www.youtube.com/results?search_query=${searchTerm}`;
            },
            
            // Hulu (provider_id: 15)
            15: async () => {
                const searchTerm = encodeURIComponent(`${title} ${year}`);
                return `https://www.hulu.com/search?q=${searchTerm}`;
            },
            
            // Disney+ (provider_id: 337)
            337: async () => {
                const searchTerm = encodeURIComponent(`${title} ${year}`);
                return `https://www.disneyplus.com/search?q=${searchTerm}`;
            },
            
            // HBO Max (provider_id: 384)
            384: async () => {
                const searchTerm = encodeURIComponent(`${title} ${year}`);
                return `https://play.max.com/search?q=${searchTerm}`;
            },
            
            // Paramount+ (provider_id: 531)
            531: async () => {
                const searchTerm = encodeURIComponent(`${title} ${year}`);
                return `https://www.paramountplus.com/search/?q=${searchTerm}`;
            },
            
            // Peacock (provider_id: 386)
            386: async () => {
                const searchTerm = encodeURIComponent(`${title} ${year}`);
                return `https://www.peacocktv.com/search?q=${searchTerm}`;
            }
        };
        
        const strategy = strategies[providerId];
        if (!strategy) {
            return null; // No strategy for this provider
        }
        
        return await strategy();
        
    } catch (error) {
        console.error(`Error resolving link for provider ${providerId}:`, error);
        return null;
    }
}

/**
 * Gets provider information by ID
 * @param {number} providerId - TMDB provider ID
 * @returns {Object|null} - Provider info or null
 */
function getProviderInfo(providerId) {
    const providers = {
        2: { name: 'Apple TV+', logo_path: '/peURlLlr8jggOwK53fJ5wdQl05y.jpg' },
        8: { name: 'Netflix', logo_path: '/t2yyOv40HZeVlLjYsCsPHnWLk4W.jpg' },
        9: { name: 'Amazon Prime Video', logo_path: '/emthp39XA2YScoYL1p0sdbAH2WA.jpg' },
        15: { name: 'Hulu', logo_path: '/aWG4R8ZJ5Ql8O8Q9Yb3k8Q9Yb3k8.jpg' },
        192: { name: 'YouTube Movies', logo_path: '/gJ8VX6JSuS59mGWgtdrnYjQp4kp.jpg' },
        337: { name: 'Disney+', logo_path: '/7rwgEs15tFwyR9NPQ5vpzxTj19Q.jpg' },
        384: { name: 'HBO Max', logo_path: '/aS2zvJWn9mwiPRbXv5Qfz91fTBO.jpg' },
        386: { name: 'Peacock', logo_path: '/xTVM8pXTnXxNSo6hdEu4ZtQoOPQ.jpg' },
        531: { name: 'Paramount+', logo_path: '/xbhHHa1YgtpwhC8lb1NQ3ACVcLd.jpg' }
    };
    
    return providers[providerId] || null;
}

module.exports = {
    resolveProviderLink,
    getProviderInfo
};
