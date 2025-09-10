#!/bin/bash

echo "🎬 MovieDrop Setup Script"
echo "========================="

# Check if we're in the right directory
if [ ! -f "MovieDrop.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Please run this script from the MovieDrop project root directory"
    exit 1
fi

echo "✅ Found Xcode project"

# Check for required tools
echo "🔍 Checking requirements..."

if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode command line tools not found. Please install Xcode."
    exit 1
fi

if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Please install Node.js 18+ from https://nodejs.org"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo "❌ npm not found. Please install npm."
    exit 1
fi

echo "✅ All requirements met"

# Setup backend
echo "🚀 Setting up backend..."
cd backend

if [ ! -f "package.json" ]; then
    echo "❌ Backend package.json not found"
    exit 1
fi

echo "📦 Installing backend dependencies..."
npm install

if [ ! -f ".env" ]; then
    echo "📝 Creating .env file from template..."
    cp env.example .env
    echo "⚠️  Please update .env with your API keys:"
    echo "   - TMDB_API_KEY: Get from https://www.themoviedb.org/settings/api"
    echo "   - MOVIEDROP_BASE_URL: Your domain (e.g., https://moviedrop.app)"
fi

cd ..

# Setup web
echo "🌐 Setting up web assets..."
cd web

if [ ! -f "index.html" ]; then
    echo "❌ Web index.html not found"
    exit 1
fi

echo "✅ Web assets ready"

cd ..

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "1. Open MovieDrop.xcodeproj in Xcode"
echo "2. Update TMDB_API_KEY in MovieService.swift files"
echo "3. Update bundle identifier in project settings"
echo "4. Start backend server: cd backend && npm run dev"
echo "5. Build and run the iOS app"
echo ""
echo "📱 The app will be available on iOS Simulator or device"
echo "🌐 Backend API will run on http://localhost:3000"
echo "💻 Web landing page can be served from the web/ directory"
echo ""
echo "Happy coding! 🎬"
