a# 🍅 Rotten Tomatoes API Integration Guide

## Overview
This guide shows you how to integrate Rotten Tomatoes data into your MovieDrop app using multiple API sources.

## 🚀 Quick Start (Recommended)

### Option 1: OMDb API (Easiest)
1. **Get API Key**: Visit [OMDb API](http://www.omdbapi.com/apikey.aspx)
2. **Add to Environment**: Add `OMDB_API_KEY=your-key-here` to your `.env` file
3. **Deploy**: Your backend will automatically use OMDb for RT data

### Option 2: Official Rotten Tomatoes API (Best Quality)
1. **Apply for Access**: Visit [Fandango Developer Portal](https://developer.fandango.com/Rotten_Tomatoes)
2. **Submit Proposal**: Explain how you'll use their data
3. **Wait for Approval**: Usually takes 1-2 weeks
4. **Add API Key**: Add `ROTTEN_TOMATOES_API_KEY=your-key-here` to your `.env` file

## 📋 Step-by-Step Setup

### 1. Choose Your API Source

#### **OMDb API (Recommended for Development)**
- ✅ **Free**: 1,000 requests/day
- ✅ **Easy Setup**: Just need email
- ✅ **Good Data**: Includes RT scores and IMDB ratings
- ❌ **Limited**: Not as comprehensive as official RT API

#### **Official Rotten Tomatoes API**
- ✅ **Best Quality**: Official RT data
- ✅ **Comprehensive**: Critic reviews, audience scores
- ❌ **Requires Approval**: Application process
- ❌ **Rate Limited**: Depends on approval

#### **RapidAPI Alternatives**
- ✅ **Multiple Sources**: Various movie APIs
- ✅ **Easy Integration**: Good documentation
- ❌ **Cost**: Usually paid after free tier
- ❌ **Variable Quality**: Depends on provider

### 2. Environment Configuration

Add these to your `moviedrop-backend/.env` file:

```bash
# Your existing TMDB key
TMDB_API_KEY=ff9ea77a49899c68788871fa1d696e26

# OMDb API (easiest to get)
OMDB_API_KEY=your-omdb-key-here

# Official RT API (when approved)
ROTTEN_TOMATOES_API_KEY=your-rt-key-here

# RapidAPI (optional)
RAPIDAPI_KEY=your-rapidapi-key-here
```

### 3. Backend Integration

The backend is already set up with:
- ✅ **RottenTomatoesService**: Handles multiple API sources
- ✅ **Enhanced Movie Endpoints**: `/movies/:id` now includes RT data
- ✅ **Dedicated RT Endpoint**: `/movies/:id/rotten-tomatoes`
- ✅ **Fallback System**: Uses mock data if APIs fail

### 4. Testing the Integration

#### Test with curl:
```bash
# Test movie details with RT data
curl "https://perceptive-flow-production.up.railway.app/api/movies/550"

# Test RT data only
curl "https://perceptive-flow-production.up.railway.app/api/movies/550/rotten-tomatoes"
```

#### Expected Response:
```json
{
  "id": 550,
  "title": "Fight Club",
  "overview": "A ticking-time-bomb...",
  "rottenTomatoes": {
    "tomatometer": 79,
    "audienceScore": 96,
    "criticsConsensus": "Fresh! Critics praise this film...",
    "source": "OMDb"
  }
}
```

## 🔧 API Key Setup Instructions

### OMDb API (Recommended)
1. Go to [OMDb API](http://www.omdbapi.com/apikey.aspx)
2. Enter your email address
3. Check your email for the API key
4. Add to your `.env` file: `OMDB_API_KEY=your-key-here`

### Official Rotten Tomatoes API
1. Visit [Fandango Developer Portal](https://developer.fandango.com/Rotten_Tomatoes)
2. Click "Apply for API Access"
3. Fill out the application form:
   - **Project Description**: "MovieDrop - A mobile app for discovering and sharing movies"
   - **Use Case**: "Display Rotten Tomatoes scores and critic reviews to help users make informed movie choices"
   - **Expected Traffic**: "Low to moderate (personal project)"
4. Wait for approval (1-2 weeks)
5. Add API key to `.env` file

### RapidAPI Alternatives
1. Visit [RapidAPI](https://rapidapi.com)
2. Search for "movie database" or "rotten tomatoes"
3. Subscribe to a service (many have free tiers)
4. Get your API key
5. Add to `.env` file

## 🎯 iOS App Integration

The iOS app is already updated to:
- ✅ **Display RT Scores**: Shows tomato icon with percentage
- ✅ **Consistent Data**: Uses hash-based scoring for mock data
- ✅ **Ready for Real Data**: Will automatically use backend RT data

### Updating iOS App for Real RT Data

When you get real API keys, the iOS app will automatically show real Rotten Tomatoes scores because it fetches movie data from your backend.

## 🚀 Deployment

### Railway Deployment
1. **Add Environment Variables** in Railway dashboard:
   ```
   OMDB_API_KEY=your-omdb-key
   ROTTEN_TOMATOES_API_KEY=your-rt-key (when approved)
   ```

2. **Redeploy**: Your backend will automatically use the new APIs

### Local Testing
1. **Update .env**: Add your API keys
2. **Restart Backend**: `npm run dev`
3. **Test**: Use curl commands above

## 📊 Data Sources Priority

The backend tries APIs in this order:
1. **OMDb API** (if key provided)
2. **Official RT API** (if approved)
3. **RapidAPI** (if key provided)
4. **Mock Data** (fallback)

## 🎨 UI Features

Your app now shows:
- 🍅 **Rotten Tomatoes Score**: With tomato icon
- ⭐ **IMDB Rating**: Star rating
- 📅 **Release Year**: Movie year
- 🎬 **Multiple Images**: Swipeable movie posters
- 💬 **Community Reviews**: Mock reviews (ready for real data)

## 🔍 Troubleshooting

### Common Issues:
1. **No RT Data**: Check API keys in `.env`
2. **Rate Limits**: OMDb has 1,000 requests/day limit
3. **API Errors**: Check console logs in backend
4. **Mock Data**: Normal if no API keys provided

### Debug Commands:
```bash
# Check if backend is running
curl "https://perceptive-flow-production.up.railway.app/health"

# Test movie with RT data
curl "https://perceptive-flow-production.up.railway.app/api/movies/550/rotten-tomatoes"
```

## 🎉 Next Steps

1. **Get OMDb API Key** (easiest option)
2. **Add to Railway Environment Variables**
3. **Test with your iOS app**
4. **Apply for Official RT API** (for better data)
5. **Consider RapidAPI** (for additional features)

Your MovieDrop app is now ready for real Rotten Tomatoes data! 🍅✨
