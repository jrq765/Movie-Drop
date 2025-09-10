#!/bin/bash

# Script to push MovieDrop project to GitHub
# Usage: ./push_to_github.sh YOUR_GITHUB_USERNAME

if [ $# -eq 0 ]; then
    echo "Usage: ./push_to_github.sh YOUR_GITHUB_USERNAME"
    echo "Example: ./push_to_github.sh jrquint"
    exit 1
fi

GITHUB_USERNAME=$1
REPO_NAME="MovieDrop"

echo "🚀 Setting up GitHub repository for MovieDrop..."
echo "GitHub Username: $GITHUB_USERNAME"
echo "Repository Name: $REPO_NAME"

# Add remote origin
echo "📡 Adding remote origin..."
git remote add origin https://github.com/$GITHUB_USERNAME/$REPO_NAME.git

# Set main branch
echo "🌿 Setting main branch..."
git branch -M main

# Push to GitHub
echo "⬆️  Pushing to GitHub..."
git push -u origin main

if [ $? -eq 0 ]; then
    echo "✅ Successfully pushed to GitHub!"
    echo "🔗 Your repository is now available at:"
    echo "   https://github.com/$GITHUB_USERNAME/$REPO_NAME"
    echo ""
    echo "📋 This link can be shared with ChatGPT for code analysis."
else
    echo "❌ Failed to push to GitHub."
    echo "💡 Make sure you have:"
    echo "   1. Created the repository on GitHub.com"
    echo "   2. Set it to Public"
    echo "   3. Have the correct permissions"
fi
