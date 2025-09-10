# MovieDrop Domain Setup Guide

## Overview
This guide explains how to configure your moviedrop.app domain to work with both your Framer website and your backend API for iMessage cards using a single domain approach.

## Current Architecture
- **Main Website**: Framer hosts your marketing site at `moviedrop.app`
- **Backend API**: Your Node.js backend serves movie data and pages at `moviedrop.app/api/*`
- **iMessage Cards**: Generate URLs like `https://moviedrop.app/m/{movieId}`

## Domain Configuration Strategy

### Single Domain Path-based Routing (Recommended)
Use your existing moviedrop.app domain with path-based routing:
- `moviedrop.app/` → Framer marketing site
- `moviedrop.app/api/*` → Your backend API
- `moviedrop.app/m/*` → Your backend movie pages

**Benefits:**
- No additional domain costs
- Simple DNS configuration
- Clean URL structure
- Easy to manage

## Step-by-Step Setup

### 1. Configure Backend Deployment
Your backend is already configured to handle:
- API routes: `/api/*`
- Movie pages: `/m/:id`
- CORS for `moviedrop.app`

### 2. Update iOS App Configuration
The iOS app has been updated to use:
- API calls: `https://moviedrop.app/api/*`
- Share URLs: `https://moviedrop.app/m/{movieId}`

### 3. Hosting Configuration Options

You have several options to route paths correctly:

#### Option A: Cloudflare (Recommended - Free)
1. Add your domain to Cloudflare
2. Configure Page Rules:
   ```
   moviedrop.app/api/* → Forward to your backend URL
   moviedrop.app/m/* → Forward to your backend URL
   moviedrop.app/* → Forward to Framer
   ```

#### Option B: Vercel (If using Vercel for backend)
1. Deploy your backend to Vercel
2. Configure `vercel.json` with rewrites:
   ```json
   {
     "rewrites": [
       {
         "source": "/api/(.*)",
         "destination": "https://your-backend.vercel.app/api/$1"
       },
       {
         "source": "/m/(.*)",
         "destination": "https://your-backend.vercel.app/m/$1"
       }
     ]
   }
   ```

#### Option C: Railway/Other Hosting
1. Deploy backend to your hosting provider
2. Use a reverse proxy or hosting provider's routing features
3. Route specific paths to your backend

### 4. Environment Variables
Update your backend environment variables:
```bash
# In your backend .env file
NODE_ENV=production
ALLOWED_ORIGINS=https://moviedrop.app
TMDB_API_KEY=your_tmdb_api_key
REGION_DEFAULT=US
```

## Testing the Setup

### 1. Test API Endpoints
```bash
# Test health check
curl https://moviedrop.app/api/health

# Test movie search
curl "https://moviedrop.app/api/movies/search?query=inception"

# Test movie page
curl https://moviedrop.app/m/27205
```

### 2. Test iMessage Card Flow
1. Open your iOS app
2. Search for a movie
3. Share it via iMessage
4. Verify the URL opens correctly in browser
5. Check that the page shows movie info and streaming options

### 3. Test Social Media Sharing
The movie pages include Open Graph meta tags for proper social media previews:
- `og:title`: Movie title and year
- `og:description`: Movie overview
- `og:image`: Movie poster
- `og:url`: Canonical movie URL

## Troubleshooting

### Common Issues:

1. **CORS Errors**
   - Ensure `api.moviedrop.app` is in your CORS origins
   - Check that preflight requests are handled

2. **DNS Propagation**
   - DNS changes can take up to 48 hours
   - Use `dig api.moviedrop.app` to check propagation

3. **SSL Certificates**
   - Ensure your backend deployment has SSL enabled
   - Vercel and Railway provide SSL by default

4. **Movie Pages Not Loading**
   - Check that the `/m/:id` route is working
   - Verify TMDB API key is configured
   - Check server logs for errors

## Security Considerations

1. **API Rate Limiting**: Consider adding rate limiting to prevent abuse
2. **Input Validation**: The backend validates movie IDs and regions
3. **CORS**: Properly configured to only allow your domains
4. **Environment Variables**: Keep API keys secure and never commit them

## Monitoring

Set up monitoring for:
- API response times
- Error rates
- Movie page load times
- DNS resolution times

## Next Steps

1. Configure DNS records in Namescheap
2. Deploy backend with new domain configuration
3. Test the complete flow
4. Monitor for any issues
5. Consider adding analytics to track usage

## Support

If you encounter issues:
1. Check server logs
2. Verify DNS propagation
3. Test API endpoints directly
4. Check CORS configuration
5. Verify environment variables
