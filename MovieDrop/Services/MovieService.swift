import Foundation

class MovieService: ObservableObject {
    private var baseURL: String {
        return Bundle.main.object(forInfoDictionaryKey: "MOVIEDROP_API_BASE_URL") as? String ?? "https://moviedrop.app/api"
    }
    
    private var watchlistBaseURL: String {
        return "https://movie-drop-production.up.railway.app/api"
    }
    
    func searchMovies(query: String) async throws -> [Movie] {
        print("🔍 MovieService: Starting search for '\(query)'")
        
        // Use consolidated backend API
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/movies?type=search&query=\(encodedQuery)") else {
            print("❌ MovieService: Invalid URL")
            throw MovieServiceError.invalidURL
        }
        
        print("🌐 MovieService: Making request to \(url)")
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 MovieService: HTTP Status: \(httpResponse.statusCode)")
            }
            
            let tmdbResponse = try JSONDecoder().decode(TMDBMovieResponse.self, from: data)
            print("✅ MovieService: Successfully decoded \(tmdbResponse.results.count) movies")
            
            // Backend returns TMDB format, so results are already Movie objects
            let movies = tmdbResponse.results
            
            // Debug: Print all movies and their poster paths
            print("🔍 All movies from TMDB:")
            for movie in movies {
                print("  - \(movie.title): poster='\(movie.posterPath ?? "nil")'")
            }
            
            // Filter out movies without posters and sort by popularity
            let filteredMovies = movies
                .filter { movie in
                    // Be more lenient - only filter out if posterPath is explicitly null/empty
                    if let posterPath = movie.posterPath {
                        if posterPath.isEmpty || posterPath == "null" {
                            print("🚫 MovieService: Filtering out movie '\(movie.title)' - empty poster path: '\(posterPath)'")
                            return false
                        }
                    } else {
                        print("🚫 MovieService: Filtering out movie '\(movie.title)' - no poster path")
                        return false
                    }
                    return true
                }
                .sorted { movie1, movie2 in
                    // Sort by popularity (higher popularity first)
                    let popularity1 = movie1.popularity ?? 0
                    let popularity2 = movie2.popularity ?? 0
                    return popularity1 > popularity2
                }
            
            print("✅ MovieService: Filtered to \(filteredMovies.count) movies with posters, sorted by popularity")
            return filteredMovies
        } catch {
            print("❌ MovieService: Error - \(error)")
            throw error
        }
    }
    
    func getMovieDetails(id: Int) async throws -> Movie {
        print("🔍 MovieService: Getting details for movie ID \(id)")
        
        guard let url = URL(string: "\(baseURL)/movies/\(id)") else {
            print("❌ MovieService: Invalid URL for movie details")
            throw MovieServiceError.invalidURL
        }
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 MovieService: HTTP Status for details: \(httpResponse.statusCode)")
            }
            
            let movie = try JSONDecoder().decode(Movie.self, from: data)
            print("✅ MovieService: Successfully got movie details for \(movie.title)")
            
            return movie
        } catch {
            print("❌ MovieService: Error getting details - \(error)")
            throw error
        }
    }
    
    // MARK: - Popular Movies for Discovery
    func getPopularMovies(excludeIds: [Int] = []) async throws -> [Movie] {
        print("🔍 MovieService: Getting randomized popular movies")
        let timestamp = Int(Date().timeIntervalSince1970)
        let randomId = Int.random(in: 1000...9999)
        var urlString = "\(baseURL)/movies?randomize=true&t=\(timestamp)&r=\(randomId)"
        if !excludeIds.isEmpty {
            let csv = excludeIds.map(String.init).joined(separator: ",")
            urlString += "&exclude=\(csv)"
        }
        print("🔗 MovieService: Calling URL: \(urlString)")
        guard let url = URL(string: urlString) else {
            print("❌ MovieService: Invalid URL for popular movies")
            throw MovieServiceError.invalidURL
        }
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 MovieService: HTTP Status for popular movies: \(httpResponse.statusCode)")
            }
            
            let tmdbResponse = try JSONDecoder().decode(TMDBMovieResponse.self, from: data)
            let filtered = tmdbResponse.results.filter { $0.posterPath != nil && $0.posterPath != "" && $0.posterPath != "null" }
            print("✅ MovieService: Got \(filtered.count) randomized popular movies")
            return filtered
        } catch {
            print("❌ MovieService: Error getting popular movies - \(error)")
            throw error
        }
    }
    
    func fetchPopularMovies() async throws -> [Movie] {
        return try await getPopularMovies()
    }
    
    // MARK: - Recommendations
    func getRecommendations(userId: Int) async throws -> [Movie] {
        print("🎯 MovieService: Getting recommendations for user \(userId)")
        
        let timestamp = Int(Date().timeIntervalSince1970)
        let randomId = Int.random(in: 1000...9999)
        let urlString = "\(watchlistBaseURL)/movies/recommendations/\(userId)?limit=20&t=\(timestamp)&r=\(randomId)"
        print("🔗 MovieService: Calling recommendations URL: \(urlString)")
        guard let url = URL(string: urlString) else {
            print("❌ MovieService: Invalid URL for recommendations")
            throw MovieServiceError.invalidURL
        }
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 MovieService: HTTP Status for recommendations: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    throw MovieServiceError.networkError
                }
            }
            
            let tmdbResponse = try JSONDecoder().decode(TMDBMovieResponse.self, from: data)
            print("✅ MovieService: Got \(tmdbResponse.results.count) recommendations")
            return tmdbResponse.results
        } catch {
            print("❌ MovieService: Failed to get recommendations: \(error)")
            throw error
        }
    }
    
    // MARK: - Watchlist Functions
    func addToWatchlist(userId: Int, movie: Movie) async throws {
        print("📝 MovieService: Adding \(movie.title) to watchlist for user \(userId)")
        
        guard let url = URL(string: "\(watchlistBaseURL)/movies/watchlist") else {
            print("❌ MovieService: Invalid URL for watchlist")
            throw MovieServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let watchlistData: [String: Any] = [
            "userId": userId,
            "movieId": movie.id,
            "movieTitle": movie.title,
            "moviePoster": movie.posterPath ?? ""
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: watchlistData)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 MovieService: HTTP Status for watchlist add: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    throw MovieServiceError.networkError
                }
            }
            
            print("✅ MovieService: Successfully added \(movie.title) to watchlist")
        } catch {
            print("❌ MovieService: Error adding to watchlist - \(error)")
            throw error
        }
    }
    
    func getWatchlist(userId: Int) async throws -> [Movie] {
        print("📋 MovieService: Getting watchlist for user \(userId)")
        
        guard let url = URL(string: "\(watchlistBaseURL)/movies/watchlist/\(userId)") else {
            print("❌ MovieService: Invalid URL for watchlist")
            throw MovieServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 MovieService: HTTP Status for watchlist: \(httpResponse.statusCode)")
            }
            
            let watchlistResponse = try JSONDecoder().decode(WatchlistResponse.self, from: data)
            print("✅ MovieService: Successfully got \(watchlistResponse.movies.count) watchlist movies")
            
            // Convert watchlist items to Movie objects
            let movies = watchlistResponse.movies.map { item in
                Movie(
                    id: item.movieId,
                    title: item.movieTitle,
                    overview: nil,
                    posterPath: item.moviePoster,
                    releaseDate: nil,
                    voteAverage: nil,
                    voteCount: nil,
                    adult: nil,
                    backdropPath: nil,
                    genreIds: nil,
                    originalLanguage: nil,
                    originalTitle: nil,
                    popularity: nil,
                    video: nil
                )
            }
            
            return movies
        } catch {
            print("❌ MovieService: Error getting watchlist - \(error)")
            throw error
        }
    }
}

// MARK: - Watchlist Response Models
struct WatchlistResponse: Codable {
    let movies: [WatchlistMovie]
}

struct WatchlistMovie: Codable {
    let id: Int
    let userId: Int
    let movieId: Int
    let movieTitle: String
    let moviePoster: String
    let listType: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case movieId = "movie_id"
        case movieTitle = "movie_title"
        case moviePoster = "movie_poster"
        case listType = "list_type"
        case createdAt = "created_at"
    }
}

enum MovieServiceError: Error {
    case invalidURL
    case noData
    case decodingError
    case networkError
}