# MovieDrop Setup Guide

## Overview
MovieDrop is a movie discovery and sharing app that helps users find where to watch movies across different streaming platforms. The app consists of:

- **iOS App**: Main movie search and discovery interface
- **Messages Extension**: Share movie recommendations via iMessage
- **Backend API**: Node.js server providing movie data and streaming information

## Prerequisites

- Node.js 18+ installed
- Xcode 15+ installed
- iOS Simulator or physical iOS device
- TMDB API key (included in setup)

## Quick Start

### 1. Backend Setup

```bash
# Navigate to backend directory
cd backend

# Install dependencies
npm install

# Start the server (API key is already configured)
TMDB_API_KEY=your_tmdb_api_key_here PORT=3000 npm start
```

The backend will start on `http://localhost:3000`

### 2. iOS App Setup

1. Open `MovieDrop.xcodeproj` in Xcode
2. Select your target device or simulator
3. Build and run the project (⌘+R)

### 3. Messages Extension Setup

1. In Xcode, select the "MovieDropMessageExtension" scheme
2. Build and run the extension
3. The extension will appear in the Messages app

## API Endpoints

### Health Check
- `GET /health` - Server health status

### Movies
- `GET /api/movies/search?query={query}` - Search for movies
- `GET /api/movies/{id}` - Get movie details
- `GET /api/movies/popular` - Get popular movies
- `GET /api/movies/trending` - Get trending movies

### Streaming
- `GET /api/streaming/platforms` - Get available streaming platforms
- `GET /api/streaming/{movieId}` - Get streaming options for a movie
- `POST /api/streaming/batch` - Get streaming options for multiple movies

## Features

### Main App
- **Movie Search**: Search for movies using TMDB API
- **Movie Details**: View detailed information about movies
- **Streaming Options**: See where movies are available to watch
- **Share Functionality**: Share movie recommendations

### Messages Extension
- **Quick Search**: Search for movies directly in Messages
- **Movie Cards**: Send rich movie cards with streaming options
- **Easy Sharing**: Share movie recommendations with friends

## Troubleshooting

### Backend Issues
- Ensure Node.js 18+ is installed
- Check that port 3000 is available
- Verify TMDB API key is valid

### iOS App Issues
- Ensure Xcode 15+ is installed
- Check that the backend is running on localhost:3000
- Verify network permissions in iOS Simulator

### Messages Extension Issues
- Ensure the main app is installed
- Check Messages app permissions
- Verify the extension is enabled in Settings > Messages > App Store

## Development Notes

- The app uses a local backend for development
- TMDB API key is included for testing
- Streaming data is currently mocked (can be integrated with JustWatch API)
- All API calls are properly error-handled

## Production Deployment

For production deployment:

1. Set up a production server
2. Update API URLs in iOS app
3. Configure proper environment variables
4. Set up database for user data
5. Integrate real streaming availability APIs
6. Add proper authentication and rate limiting

## Support

If you encounter any issues:
1. Check the console logs in Xcode
2. Verify the backend is running and accessible
3. Test API endpoints directly using curl or Postman
4. Ensure all dependencies are properly installed
