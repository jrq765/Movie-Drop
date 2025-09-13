module.exports = async (req, res) => {
  // Set CORS headers
  res.setHeader('Access-Control-Allow-Origin', 'https://moviedrop.app');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }
  
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  const { id } = req.query;
  const region = req.query.region || 'US';
  
  if (!id) {
    return res.status(400).json({ error: 'Missing movie id' });
  }

  const TMDB_KEY = process.env.TMDB_API_KEY;
  if (!TMDB_KEY) {
    return res.status(500).json({
      error: 'Missing TMDB_API_KEY',
      restore: [
        'Add TMDB_API_KEY to your Vercel project Environment Variables',
        'Redeploy, then GET /api/health should return { ok: true }'
      ]
    });
  }

  try {
    // Fetch movie details
    const movieUrl = `https://api.themoviedb.org/3/movie/${id}?api_key=${TMDB_KEY}`;
    const movieResponse = await fetch(movieUrl);
    
    if (!movieResponse.ok) {
      return res.status(movieResponse.status).json({ error: 'Movie not found' });
    }
    
    const movie = await movieResponse.json();
    
    // Fetch streaming providers
    const providersUrl = `https://api.themoviedb.org/3/movie/${id}/watch/providers?api_key=${TMDB_KEY}`;
    const providersResponse = await fetch(providersUrl);
    const providersData = await providersResponse.ok ? await providersResponse.json() : { results: {} };
    
    const regionData = providersData?.results?.[region.toUpperCase()];
    const tmdbRegionLink = regionData?.link || `https://www.themoviedb.org/movie/${id}/watch?locale=${region}`;

    // Function to generate direct streaming service URLs
    const getDirectStreamingURL = (provider, movieTitle, movieYear) => {
      const title = encodeURIComponent(movieTitle);
      const year = movieYear || '';
      
      // Direct streaming platform URLs - these go directly to the movie, not search pages
      const directUrls = {
        // Netflix - direct movie URLs (when available)
        8: `https://www.netflix.com/title/${provider.provider_id}`, // Netflix uses internal IDs
        
        // Disney+ - direct search that should find the movie
        337: `https://www.disneyplus.com/search?q=${title}`,
        
        // Hulu - direct search
        15: `https://www.hulu.com/search?q=${title}`,
        
        // Paramount+ - direct search
        531: `https://www.paramountplus.com/search?q=${title}`,
        
        // Apple TV+ - direct search
        350: `https://tv.apple.com/search?term=${title}`,
        
        // Peacock - direct search
        386: `https://www.peacocktv.com/search?q=${title}`,
        387: `https://www.peacocktv.com/search?q=${title}`,
        
        // Max (HBO Max) - direct search
        1899: `https://play.max.com/search?q=${title}`,
        384: `https://play.max.com/search?q=${title}`, // Alternative HBO Max ID
        
        // Amazon Prime Video - direct search
        9: `https://www.amazon.com/s?k=${title}&i=movies-tv`,
        10: `https://www.amazon.com/s?k=${title}&i=movies-tv`,
        
        // Apple TV (rent/buy) - direct search
        2: `https://tv.apple.com/search?term=${title}`,
        
        // Google Play - direct search
        3: `https://play.google.com/store/search?q=${title}&c=movies`,
        
        // Microsoft Store - direct search
        68: `https://www.microsoft.com/en-us/store/search?q=${title}`,
        
        // Vudu - direct search
        7: `https://www.vudu.com/content/movies/search?q=${title}`,
        
        // YouTube - direct search
        192: `https://www.youtube.com/results?search_query=${title}+movie`,
        
        // Plex - direct search
        538: `https://watch.plex.tv/search?q=${title}`,
      };
      
      return directUrls[provider.provider_id] || null;
    };

    // Extract providers by type
    const kinds = ['flatrate', 'rent', 'buy'];
    const providers = [];

    if (regionData) {
      for (const kind of kinds) {
        const arr = regionData[kind] || [];
        for (const p of arr) {
          const directUrl = getDirectStreamingURL(p, movie.title, movie.release_date?.slice(0,4));
          if (directUrl) { // Only include providers with direct links
            providers.push({
              id: p.provider_id,
              name: p.provider_name,
              logo_path: p.logo_path,
              kind,
              url: directUrl
            });
          }
        }
      }
    }

    // Dedupe by provider id + kind
    const key = (x) => `${x.id}:${x.kind}`;
    const dedup = Object.values(
      providers.reduce((acc, cur) => ((acc[key(cur)] = acc[key(cur)] || cur), acc), {})
    );

    // Return HTML page for the movie
    const html = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${movie.title} - MovieDrop</title>
    <meta property="og:title" content="${movie.title}">
    <meta property="og:description" content="${movie.overview || 'Watch this movie on your favorite streaming platform'}">
    <meta property="og:image" content="https://image.tmdb.org/t/p/w500${movie.poster_path}">
    <meta property="og:url" content="https://moviedrop.app/m/${id}">
    <meta property="og:type" content="video.movie">
    <!-- Universal Links disabled for now to ensure web page works on iOS -->
    <!-- <meta name="apple-itunes-app" content="app-argument=movie://${id}"> -->
    <!-- <link rel="alternate" href="moviedrop://movie/${id}" /> -->
    <style>
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
            margin: 0; 
            padding: 20px; 
            background: linear-gradient(135deg, #000000 0%, #1a1a1a 100%);
            min-height: 100vh;
        }
        .container { 
            max-width: 800px; 
            margin: 0 auto; 
            background: rgba(255, 255, 255, 0.05); 
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 12px; 
            overflow: hidden;
            box-shadow: 0 20px 40px rgba(0,0,0,0.3);
            backdrop-filter: blur(10px);
        }
        .hero { 
            background: linear-gradient(45deg, #F85536, #ff6b47);
            color: white; 
            padding: 40px; 
            text-align: center;
        }
        .poster { 
            width: 200px; 
            height: 300px; 
            object-fit: cover; 
            border-radius: 8px; 
            margin: 0 auto 20px;
            display: block;
        }
        .title { 
            font-size: 2.5em; 
            margin: 0 0 10px; 
            font-weight: 700;
        }
        .year { 
            font-size: 1.2em; 
            opacity: 0.8; 
            margin-bottom: 20px;
        }
        .overview { 
            font-size: 1.1em; 
            line-height: 1.6; 
            opacity: 0.9;
            max-width: 600px;
            margin: 0 auto;
        }
        .content { 
            padding: 40px; 
            color: white;
        }
        .providers { 
            margin-top: 30px; 
        }
        .provider-grid { 
            display: grid; 
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); 
            gap: 15px; 
            margin-top: 20px;
        }
        .provider { 
            display: flex; 
            align-items: center; 
            padding: 15px; 
            border: 2px solid rgba(255, 255, 255, 0.2); 
            border-radius: 8px; 
            text-decoration: none; 
            color: white; 
            background: rgba(255, 255, 255, 0.05);
            transition: all 0.3s ease;
        }
        .provider:hover { 
            border-color: #F85536; 
            background: rgba(248, 85, 54, 0.1);
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(248, 85, 54, 0.3);
        }
        .provider-logo { 
            width: 40px; 
            height: 40px; 
            object-fit: contain; 
            margin-right: 15px; 
            border-radius: 4px;
        }
        .provider-info h3 { 
            margin: 0 0 5px; 
            font-size: 1.1em;
        }
        .provider-info p { 
            margin: 0; 
            font-size: 0.9em; 
            color: #cccccc;
        }
        .kind-badge {
            background: #F85536;
            color: white;
            padding: 2px 8px;
            border-radius: 12px;
            font-size: 0.8em;
            margin-left: 10px;
        }
        .no-providers {
            text-align: center;
            color: #cccccc;
            font-style: italic;
            margin: 40px 0;
        }
        .footer {
            text-align: center;
            padding: 20px;
            color: #cccccc;
            border-top: 1px solid rgba(255, 255, 255, 0.1);
        }
        .app-banner {
            background: rgba(248, 85, 54, 0.1);
            border: 1px solid #F85536;
            border-radius: 8px;
            padding: 15px;
            margin-bottom: 20px;
            text-align: center;
        }
        .app-banner h3 {
            color: #F85536;
            margin: 0 0 10px;
        }
        .app-banner p {
            color: #cccccc;
            margin: 0 0 15px;
            font-size: 0.9rem;
        }
        .app-button {
            background: #F85536;
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 6px;
            font-size: 1rem;
            font-weight: 600;
            cursor: pointer;
            text-decoration: none;
            display: inline-block;
            transition: all 0.3s ease;
        }
        .app-button:hover {
            background: #e6472a;
            transform: translateY(-1px);
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="hero">
            ${movie.poster_path ? `<img src="https://image.tmdb.org/t/p/w500${movie.poster_path}" alt="${movie.title}" class="poster">` : ''}
            <h1 class="title">${movie.title}</h1>
            <div class="year">${movie.release_date ? new Date(movie.release_date).getFullYear() : ''}</div>
            <div class="overview">${movie.overview || 'No description available.'}</div>
        </div>
        
        <div class="content">
            <div class="app-banner">
                <h3>📱 Have the MovieDrop App?</h3>
                <p>Open this movie in the app for a better experience</p>
                <a href="moviedrop://movie/${id}" class="app-button" id="openInApp">Open in App</a>
            </div>
            
            <h2>Where to Watch</h2>
            <div class="providers">
                ${dedup.length > 0 ? `
                    <div class="provider-grid">
                        ${dedup.map(provider => `
                            <a href="${provider.url}" class="provider" target="_blank">
                                ${provider.logo_path ? `<img src="https://image.tmdb.org/t/p/w92${provider.logo_path}" alt="${provider.name}" class="provider-logo">` : ''}
                                <div class="provider-info">
                                    <h3>${provider.name} <span class="kind-badge">${provider.kind}</span></h3>
                                    <p>Click to watch</p>
                                </div>
                            </a>
                        `).join('')}
                    </div>
                ` : `
                    <div class="no-providers">
                        <p>No streaming providers available for this region (${region.toUpperCase()}).</p>
                        <p><a href="${tmdbRegionLink}" target="_blank">Check TMDB for more options</a></p>
                    </div>
                `}
            </div>
        </div>
        
        <div class="footer">
            <p>Powered by <strong>MovieDrop</strong> • Data from TMDB</p>
        </div>
    </div>

    <script>
        // Enhanced app detection and deep linking
        (function() {
            const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent);
            const isAndroid = /Android/.test(navigator.userAgent);
            const isMobile = isIOS || isAndroid;
            
            console.log('Device detected:', { isIOS, isAndroid, isMobile });
            
            // Handle app button click with fallback
            const openInAppButton = document.getElementById('openInApp');
            if (openInAppButton) {
                openInAppButton.addEventListener('click', function(e) {
                    e.preventDefault();
                    console.log('App button clicked - attempting to open app');
                    
                    const appUrl = 'moviedrop://movie/${id}';
                    const universalLink = 'https://moviedrop.app/m/${id}';
                    
                    // Try custom scheme first
                    const iframe = document.createElement('iframe');
                    iframe.style.display = 'none';
                    iframe.src = appUrl;
                    document.body.appendChild(iframe);
                    
                    // Set a timeout to redirect to universal link if app doesn't open
                    setTimeout(() => {
                        document.body.removeChild(iframe);
                        console.log('App not opened, redirecting to universal link');
                        window.location.href = universalLink;
                    }, 2000);
                });
            }
            
            // Auto-detect if user is coming from the app (for better UX)
            const urlParams = new URLSearchParams(window.location.search);
            const fromApp = urlParams.get('fromApp');
            if (fromApp === 'true') {
                console.log('User came from app - hiding app banner');
                const appBanner = document.querySelector('.app-banner');
                if (appBanner) {
                    appBanner.style.display = 'none';
                }
            }
        })();
    </script>
</body>
</html>`;

    res.setHeader('Content-Type', 'text/html');
    res.setHeader('Cache-Control', 's-maxage=300, stale-while-revalidate=600');
    return res.status(200).send(html);
    
  } catch (error) {
    console.error('Error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};
