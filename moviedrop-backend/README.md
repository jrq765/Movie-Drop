# MovieDrop Backend

A Node.js backend API for the MovieDrop app with PostgreSQL database support.

## Features

- User authentication (register, login, logout)
- Movie search and details via TMDB API
- Streaming provider information
- User movie lists (watchlist, watched, favorites)
- Friend system and group lists
- Movie ratings and reviews

## Setup

1. Install dependencies:
   ```bash
   npm install
   ```

2. Set up environment variables:
   ```bash
   cp env.example .env
   ```
   
   Update the `.env` file with your configuration:
   - `DATABASE_URL`: PostgreSQL connection string
   - `JWT_SECRET`: Secret key for JWT tokens
   - `TMDB_API_KEY`: The Movie Database API key
   - `CORS_ORIGIN`: Allowed CORS origins

3. Initialize the database:
   ```bash
   npm run migrate
   ```

4. Start the development server:
   ```bash
   npm run dev
   ```

## Railway Deployment

1. Install Railway CLI:
   ```bash
   npm install -g @railway/cli
   ```

2. Login to Railway:
   ```bash
   railway login
   ```

3. Create a new project:
   ```bash
   railway init
   ```

4. Add PostgreSQL database:
   ```bash
   railway add postgresql
   ```

5. Set environment variables:
   ```bash
   railway variables set JWT_SECRET=your-super-secret-jwt-key
   railway variables set TMDB_API_KEY=your-tmdb-api-key
   railway variables set CORS_ORIGIN=https://your-frontend-domain.com
   ```

6. Deploy:
   ```bash
   railway up
   ```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/me` - Get current user
- `POST /api/auth/logout` - Logout user

### Movies
- `GET /api/movies/popular` - Get popular movies
- `GET /api/movies/search?query=...` - Search movies
- `GET /api/movies/:id` - Get movie details

### Streaming
- `GET /api/streaming/:id?region=US` - Get streaming providers

## Database Schema

The application automatically creates the following tables:
- `users` - User accounts
- `user_sessions` - JWT token management
- `user_movie_lists` - Personal movie lists
- `user_friends` - Friend relationships
- `group_lists` - Group movie lists
- `group_list_members` - Group membership
- `group_list_movies` - Movies in group lists
