# MovieDrop Web - Branded Landing Pages

This is your branded movie landing page system that creates Linktree-style pages for each movie shared through the iMessage extension.

## 🎬 Features

- **Branded Design**: Custom MovieDrop branding with gradient header
- **Dynamic Movie Pages**: Each movie gets a unique URL like `/m/12345?region=US`
- **Real Streaming Data**: Fetches actual availability from TMDB API
- **Direct Provider Links**: Links directly to Netflix, Prime Video, Hulu, etc.
- **Responsive Design**: Works perfectly on mobile and desktop
- **Fallback Support**: Graceful handling when data isn't available

## 🚀 Quick Start

### Local Development

1. **Install dependencies**:
   ```bash
   cd web
   npm install
   ```

2. **Start the server**:
   ```bash
   npm start
   ```

3. **Test a movie page**:
   ```
   http://localhost:3000/m/550?region=US
   ```

### Deploy to Vercel

1. **Install Vercel CLI**:
   ```bash
   npm i -g vercel
   ```

2. **Deploy**:
   ```bash
   vercel --prod
   ```

3. **Update your domain** in iOS app's `Info.plist`:
   ```xml
   <key>MOVIEDROP_BASE_URL</key>
   <string>https://your-vercel-domain.vercel.app</string>
   ```

## 📱 How It Works

1. **User taps movie** in iMessage extension
2. **Creates message** with URL like `https://moviedrop.framer.website/m/12345?region=US`
3. **Recipient taps card** → Opens your branded landing page
4. **Page loads movie details** from TMDB API
5. **Shows streaming providers** with direct links
6. **User clicks provider** → Goes directly to watch the movie

## 🎨 Customization

### Branding
- Edit the gradient colors in the CSS
- Change the logo text in the HTML
- Update the tagline

### Providers
- Add new providers in the `PROVIDER_LOGOS` object
- Customize provider link generation in `getProviderLink()`

### Styling
- Modify the CSS in the `<style>` section
- Change colors, fonts, layout as needed

## 🔧 Configuration

### Environment Variables
- `PORT`: Server port (default: 3000)
- `TMDB_API_KEY`: Your TMDB API key (hardcoded for now)

### TMDB API Key
The API key is currently hardcoded in the HTML. For production, you should:
1. Move it to environment variables
2. Use a backend proxy to hide the key
3. Or use server-side rendering

## 📊 Example URLs

- **Fight Club**: `https://moviedrop.framer.website/m/550?region=US`
- **Dune**: `https://moviedrop.framer.website/m/438631?region=US`
- **Inception**: `https://moviedrop.framer.website/m/27205?region=US`

## 🛠️ Technical Details

- **Frontend**: Vanilla HTML/CSS/JavaScript
- **Backend**: Express.js for routing
- **API**: TMDB API for movie data and streaming providers
- **Deployment**: Vercel (serverless functions)

## 🎯 Next Steps

1. **Deploy to Vercel** and get your domain
2. **Update iOS app** with the new domain
3. **Test the full flow** from iMessage to landing page
4. **Customize branding** to match your vision
5. **Add analytics** to track usage

Your branded movie landing pages are ready to go! 🎬✨