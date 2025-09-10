# MovieDrop 🎬

Share movies instantly with friends in text messages. Instead of sending clunky trailer links, MovieDrop creates smart movie cards with streaming availability and one-tap access to watch, rent, or buy.

## Features

- **Smart Movie Search**: Find any movie instantly with TMDB API integration
- **iMessage Integration**: Share movie cards directly in iMessage with one-tap insertion
- **Real Streaming Data**: See exactly where to watch, rent, or buy with live TMDB provider data
- **Universal Links**: Framer-powered landing pages with region-specific provider links
- **Direct Provider Access**: One-tap links to streaming platforms (when resolvable)
- **Affiliate Monetization**: Earn commissions from streaming platform referrals

## Tech Stack

### iOS App
- **SwiftUI**: Modern iOS UI framework
- **Message Extension**: iMessage integration for sharing
- **TMDB API**: Movie data and metadata
- **JustWatch API**: Streaming availability (planned)

### Backend
- **Node.js + Express**: RESTful API server
- **TMDB API**: Movie search and details
- **Firebase**: Database and authentication (planned)
- **Analytics**: Track shares, clicks, and conversions

### Web
- **HTML5 + CSS3**: Responsive landing page
- **Vanilla JavaScript**: Interactive features
- **Progressive Web App**: Mobile-optimized experience

## Project Structure

```
MovieDrop/
├── MovieDrop/                          # iOS App
│   ├── MovieDropApp.swift             # Main app entry point
│   ├── ContentView.swift              # Main app interface
│   ├── Models/
│   │   └── Movie.swift                # Movie data models
│   ├── Services/
│   │   └── MovieService.swift         # API service layer
│   └── Assets.xcassets/               # App icons and assets
├── MovieDropMessageExtension/          # iMessage Extension
│   ├── MessagesViewController.swift   # Extension interface
│   └── MainInterface.storyboard       # Extension UI
├── backend/                           # Node.js API
│   ├── server.js                      # Express server
│   ├── routes/
│   │   ├── movies.js                  # Movie endpoints
│   │   ├── streaming.js               # Streaming availability
│   │   └── analytics.js               # Analytics tracking
│   └── package.json                   # Dependencies
├── web/                               # Landing page
│   ├── index.html                     # Main page
│   ├── styles.css                     # Styling
│   └── script.js                      # JavaScript
└── README.md                          # This file
```

## Setup Instructions

### Prerequisites

- Xcode 15.0+ (for iOS development)
- Node.js 18.0+ (for backend)
- TMDB API key (free at [themoviedb.org](https://www.themoviedb.org/settings/api))

### iOS App Setup

1. Open `MovieDrop.xcodeproj` in Xcode
2. Update the bundle identifier in project settings
3. Add your TMDB API key to `MovieService.swift`
4. Build and run on iOS Simulator or device

### Backend Setup

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Copy environment variables:
   ```bash
   cp env.example .env
   ```

4. Update `.env` with your API keys:
   ```env
   TMDB_API_KEY=your_tmdb_api_key_here
   MOVIEDROP_BASE_URL=https://moviedrop.app
   ```

5. Start the development server:
   ```bash
   npm run dev
   ```

The API will be available at `http://localhost:3000`

### Web Setup

1. Navigate to the web directory:
   ```bash
   cd web
   ```

2. Serve the files using any static server:
   ```bash
   # Using Python
   python -m http.server 8000
   
   # Using Node.js
   npx serve .
   
   # Using PHP
   php -S localhost:8000
   ```

The web app will be available at `http://localhost:8000`

## Testing the Implementation

### Quick Tests

1. **iMessage Sharing Test**:
   - Open iMessage and tap the MovieDrop extension
   - Search for any movie (e.g., "Inception")
   - Tap a movie → exactly one bubble should insert
   - Tap Send to share the message

2. **Universal Link Test**:
   - On recipient device (no app installed), tap the shared bubble
   - Should open: `https://moviedrop.framer.website/m/{tmdbId}?region=US`
   - Page should show movie details and real provider data

3. **Provider Link Test**:
   - On the Framer page, click any provider chip
   - Should open the provider's movie page (when resolvable)
   - Or fall back to TMDB region page

### Backend API Test

Test the streaming API with a real movie:

```bash
# Test with a popular movie (Inception - TMDB ID: 27205)
curl "http://localhost:3000/api/streaming/27205?region=US"

# Expected response:
{
  "region": "US",
  "movieId": 27205,
  "movieTitle": "Inception",
  "movieYear": 2010,
  "link": "https://www.justwatch.com/us/movie/inception",
  "providers": [
    {
      "id": 8,
      "name": "Netflix",
      "logo_path": "/t2yyOv40HZeVlLjYsCsPHnWLk4W.jpg",
      "kinds": ["flatrate"],
      "url": "https://www.justwatch.com/us/movie/inception",
      "isDirectLink": false
    }
  ]
}
```

### Restoration Checklist

If something fails, check these:

**iOS ATS Issues**:
- Add domain-specific ATS exception for `moviedrop.framer.website` in Info.plist
- Ensure `image.tmdb.org` is allowed for poster loading

**Missing TMDB Key**:
- Get API key from https://www.themoviedb.org/settings/api
- Add `TMDB_API_KEY=your_actual_key` to `backend/.env`
- Restart backend server

**Framer Issues**:
- Ensure `/m/[id]` route exists on Framer
- Verify site is published at `moviedrop.framer.website`
- Test universal link manually in browser

## API Endpoints

### Movies
- `GET /api/movies/search?query={query}` - Search movies
- `GET /api/movies/{id}` - Get movie details
- `POST /api/movies/{id}/card` - Create movie card
- `GET /api/movies/popular` - Get popular movies
- `GET /api/movies/trending` - Get trending movies

### Streaming
- `GET /api/streaming/{movieId}` - Get streaming availability
- `POST /api/streaming/batch` - Get batch streaming data
- `POST /api/streaming/click` - Track streaming clicks
- `GET /api/streaming/platforms` - Get supported platforms

### Analytics
- `POST /api/analytics/share` - Track movie card shares
- `POST /api/analytics/click` - Track clicks
- `POST /api/analytics/search` - Track searches
- `GET /api/analytics/summary` - Get analytics summary

## Monetization Strategy

### Phase 1: Affiliate Links
- Amazon Prime Video (2-4% commission)
- Apple TV (5-7% commission)
- YouTube Movies (varies)
- Direct streaming platform partnerships

### Phase 2: In-App Ads
- Native movie advertisements
- Sponsored movie recommendations
- Banner ads on web landing pages

### Phase 3: Subscription Tier
- $2.99/month premium subscription
- Ad-free experience
- AI-powered movie recommendations
- Advanced sharing features

## Development Roadmap

### MVP (Current)
- [x] iOS app with movie search
- [x] iMessage extension for sharing
- [x] Web landing page for shared links
- [x] Basic backend API
- [x] TMDB integration

### Phase 2
- [x] Real TMDB streaming provider data integration
- [x] Universal links with Framer landing pages
- [x] Direct provider link resolution
- [ ] User accounts and watch history
- [ ] Push notifications for new releases
- [ ] Enhanced movie card designs

### Phase 3
- [ ] AI recommendation engine
- [ ] Social features (friend recommendations)
- [ ] Advanced analytics dashboard
- [ ] Multi-platform support (Android, web app)

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support, email support@moviedrop.app or join our Discord community.

---

**MovieDrop** - Share movies instantly with friends 🎬
