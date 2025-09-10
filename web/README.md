# MovieDrop Web App

This is the web component of MovieDrop that handles universal links from the iOS iMessage extension.

## Features

- **Universal Links**: Handles `/m/[id]` routes for movie sharing
- **Real TMDB Data**: Fetches movie information and streaming availability from TMDB API
- **Responsive Design**: Works on mobile and desktop
- **Ad Integration**: Optional Google Ad Manager integration
- **SEO Optimized**: Proper meta tags and Open Graph data

## Environment Variables

Create a `.env.local` file with the following variables:

```bash
# Required
TMDB_API_KEY=your_tmdb_api_key_here

# App Configuration
NEXT_PUBLIC_BASE_URL=https://moviedrop.app
NEXT_PUBLIC_REGION_DEFAULT=US

# Optional - App Store
NEXT_PUBLIC_APP_STORE_URL=https://apps.apple.com/app/idXXXXXXXXX

# Optional - Google Ad Manager
NEXT_PUBLIC_GAM_NETWORK=123456
NEXT_PUBLIC_GAM_SLOT_LEFT=/1234567/moviedrop_left
NEXT_PUBLIC_GAM_SLOT_RIGHT=/1234567/moviedrop_right
```

## Setup

1. **Install dependencies**:
   ```bash
   cd web
   npm install
   ```

2. **Set up environment variables**:
   ```bash
   cp .env.example .env.local
   # Edit .env.local with your actual values
   ```

3. **Run development server**:
   ```bash
   npm run dev
   ```

4. **Build for production**:
   ```bash
   npm run build
   npm start
   ```

## Universal Links Setup

### For Development
The universal links are configured in `/public/.well-known/apple-app-site-association`. 

### For Production
1. Update the `appID` in the apple-app-site-association file with your actual Team ID
2. Ensure the file is served at `https://moviedrop.app/.well-known/apple-app-site-association`
3. Add Associated Domains capability to your iOS app:
   - Add `applinks:moviedrop.app` to your app's Associated Domains

## Testing

### Manual Test Plan

1. **iMessage Extension**:
   - Open Messages app
   - Tap MovieDrop extension
   - Search for a movie (e.g., "Dune")
   - Tap a movie result
   - Verify one message bubble appears with universal link
   - Extension should compact to show Send button

2. **Universal Link**:
   - Tap the message bubble
   - Safari should open `https://moviedrop.app/m/[movieId]`
   - Page should show:
     - Movie poster, title, year, runtime
     - Movie overview
     - "Where to watch" section with streaming providers
     - MovieDrop logo and App Store badge (if configured)

3. **Desktop**:
   - Visit the URL directly in browser
   - Should see left/right ad slots (if GAM configured)
   - Mobile: ad slots should be hidden

## API Integration

The app uses the TMDB API for:
- Movie details (`/movie/{id}`)
- Watch providers (`/movie/{id}/watch/providers`)

All data is real - no mock data is used. If API calls fail, the page will show a 404 error.

## Ad Integration

Google Ad Manager integration is optional:
- If `NEXT_PUBLIC_GAM_*` environment variables are set, ad slots will render
- If not set, ad slots are hidden completely
- Ads only show on desktop (lg+ breakpoint)

## Deployment

The app is designed to be deployed to Vercel:
1. Connect your GitHub repository to Vercel
2. Set environment variables in Vercel dashboard
3. Deploy automatically on push to main branch

## Troubleshooting

### Common Issues

1. **"Movie not found" errors**:
   - Check TMDB_API_KEY is set correctly
   - Verify the movie ID exists in TMDB

2. **Universal links not working**:
   - Ensure apple-app-site-association file is accessible
   - Check Associated Domains capability is added to iOS app
   - Verify Team ID matches in the association file

3. **Images not loading**:
   - Check ATS settings in iOS app
   - Ensure image.tmdb.org is allowed in Info.plist

### Restoration Checklist

If the app is not working, check:

- [ ] TMDB_API_KEY environment variable is set
- [ ] Backend server is running on port 3000
- [ ] iOS app has correct base URL (192.168.0.31:3000 for local testing)
- [ ] ATS exceptions are configured for moviedrop.app and image.tmdb.org
- [ ] Universal links association file is accessible
- [ ] Associated Domains capability is added to iOS app
