const express = require('express');
const axios = require('axios');

const router = express.Router();

// Get streaming providers for a movie
router.get('/:id', async (req, res) => {
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

    // Remove TMDB fallback links and combine rent/buy for same provider
    const dedupedProviders = {};
    
    // Process flatrate (streaming)
    if (processedProviders.flatrate.length > 0) {
      dedupedProviders.flatrate = processedProviders.flatrate.map(provider => ({
        provider_id: provider.provider_id,
        provider_name: provider.provider_name,
        logo_path: provider.logo_path,
        display_priority: provider.display_priority
      }));
    }

    // Combine rent and buy options for same provider
    const combinedProviders = {};
    
    // Process rent options
    processedProviders.rent.forEach(provider => {
      const key = provider.provider_id;
      if (!combinedProviders[key]) {
        combinedProviders[key] = {
          provider_id: provider.provider_id,
          provider_name: provider.provider_name,
          logo_path: provider.logo_path,
          display_priority: provider.display_priority,
          kind: 'rent'
        };
      } else {
        combinedProviders[key].kind = 'rent/buy';
      }
    });

    // Process buy options
    processedProviders.buy.forEach(provider => {
      const key = provider.provider_id;
      if (!combinedProviders[key]) {
        combinedProviders[key] = {
          provider_id: provider.provider_id,
          provider_name: provider.provider_name,
          logo_path: provider.logo_path,
          display_priority: provider.display_priority,
          kind: 'buy'
        };
      } else {
        combinedProviders[key].kind = 'rent/buy';
      }
    });

    // Convert to array and sort by display priority
    dedupedProviders.purchase = Object.values(combinedProviders)
      .sort((a, b) => a.display_priority - b.display_priority);

    res.json(dedupedProviders);

  } catch (error) {
    console.error('Error fetching streaming providers:', error);
    res.status(500).json({ error: 'Failed to fetch streaming providers' });
  }
});

module.exports = router;
