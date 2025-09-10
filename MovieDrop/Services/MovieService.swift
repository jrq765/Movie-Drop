import Foundation

class MovieService: ObservableObject {
    private var baseURL: String {
        return Bundle.main.object(forInfoDictionaryKey: "MOVIEDROP_API_BASE_URL") as? String ?? "https://moviedrop-backend.vercel.app/api"
    }
    
    func searchMovies(query: String) async throws -> [Movie] {
        print("🔍 MovieService: Starting search for '\(query)'")
        
        // Use TMDB API directly
        let tmdbApiKey = "778d52dd5314bd2cefb20648cdf8842f"
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.themoviedb.org/3/search/movie?api_key=\(tmdbApiKey)&query=\(encodedQuery)&language=en-US") else {
            print("❌ MovieService: Invalid URL")
            throw MovieServiceError.invalidURL
        }
        
        print("🌐 MovieService: Making request to \(url)")
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
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
            
            // Filter out movies without posters and sort by popularity
            let filteredMovies = movies
                .filter { movie in
                    guard let posterPath = movie.posterPath, !posterPath.isEmpty else {
                        print("🚫 MovieService: Filtering out movie '\(movie.title)' - no poster")
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
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")
        
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