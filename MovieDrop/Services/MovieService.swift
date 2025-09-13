import Foundation

class MovieService: ObservableObject {
    private var baseURL: String {
        return Bundle.main.object(forInfoDictionaryKey: "MOVIEDROP_API_BASE_URL") as? String ?? "https://moviedrop-backend.vercel.app/api"
    }
    
    func searchMovies(query: String) async throws -> [Movie] {
        print("🔍 MovieService: Starting search for '\(query)'")
        
        // Use TMDB API directly
        let tmdbApiKey = Bundle.main.object(forInfoDictionaryKey: "TMDB_API_KEY") as? String ?? ""
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.themoviedb.org/3/search/movie?api_key=\(tmdbApiKey)&query=\(encodedQuery)&language=en-US") else {
            print("❌ MovieService: Invalid URL")
            throw MovieServiceError.invalidURL
        }
        
        print("🌐 MovieService: Making request to \(url)")
        
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 15)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 MovieService: HTTP Status: \(httpResponse.statusCode)")
            }
            
            let tmdbResponse = try JSONDecoder().decode(TMDBMovieResponse.self, from: data)
            print("✅ MovieService: Successfully decoded \(tmdbResponse.results.count) movies")
            
            // TMDB results are already Movie objects, no conversion needed
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
        
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 15)
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
}

enum MovieServiceError: Error {
    case invalidURL
    case noData
    case decodingError
}