import Foundation

class MovieService: ObservableObject {
    private var baseURL: String {
        return Bundle.main.object(forInfoDictionaryKey: "MOVIEDROP_API_BASE_URL") as? String ?? "https://moviedrop.app/api"
    }
    
    func searchMovies(query: String, completion: @escaping (Result<[Movie], Error>) -> Void) {
        // Use TMDB API directly
        let tmdbApiKey = Bundle.main.object(forInfoDictionaryKey: "TMDB_API_KEY") as? String ?? ""
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.themoviedb.org/3/search/movie?api_key=\(tmdbApiKey)&query=\(encodedQuery)&language=en-US") else {
            print("❌ Invalid URL for query: \(query)")
            completion(.failure(MovieServiceError.invalidURL))
            return
        }
        
        print("🔍 Searching for: \(query)")
        print("🌐 URL: \(url)")
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Network error: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                print("❌ No data received")
                completion(.failure(MovieServiceError.noData))
                return
            }
            
            // Print raw response for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Raw response: \(jsonString)")
            }
            
            do {
                let tmdbResponse = try JSONDecoder().decode(TMDBMovieResponse.self, from: data)
                print("✅ Found \(tmdbResponse.results.count) movies")
                
                // Debug: Print all movies and their poster paths
                print("🔍 All movies from TMDB:")
                for movie in tmdbResponse.results {
                    print("  - \(movie.title): poster='\(movie.posterPath ?? "nil")'")
                }
                
                // Filter out movies without posters and sort by popularity
                let filteredMovies = tmdbResponse.results
                    .filter { movie in
                        // Be more lenient - only filter out if posterPath is explicitly null/empty
                        if let posterPath = movie.posterPath {
                            if posterPath.isEmpty || posterPath == "null" {
                                print("🚫 Filtering out movie '\(movie.title)' - empty poster path: '\(posterPath)'")
                                return false
                            }
                        } else {
                            print("🚫 Filtering out movie '\(movie.title)' - no poster path")
                            return false
                        }
                        return true
                    }
                    .sorted { (movie1: Movie, movie2: Movie) -> Bool in
                        // Sort by popularity (higher popularity first)
                        let popularity1 = movie1.popularity ?? 0
                        let popularity2 = movie2.popularity ?? 0
                        return popularity1 > popularity2
                    }
                
                print("✅ Filtered to \(filteredMovies.count) movies with posters, sorted by popularity")
                if filteredMovies.isEmpty {
                    print("⚠️ No movies with posters found")
                } else {
                    print("📋 First movie: \(filteredMovies[0].title)")
                }
                completion(.success(filteredMovies))
            } catch {
                print("❌ Decoding error: \(error)")
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("❌ Missing key: \(key) - \(context)")
                    case .typeMismatch(let type, let context):
                        print("❌ Type mismatch: \(type) - \(context)")
                    case .valueNotFound(let type, let context):
                        print("❌ Value not found: \(type) - \(context)")
                    case .dataCorrupted(let context):
                        print("❌ Data corrupted: \(context)")
                    @unknown default:
                        print("❌ Unknown decoding error")
                    }
                }
                completion(.failure(error))
            }
        }.resume()
    }
    
    func getMovieDetails(movieId: Int, completion: @escaping (Result<Movie, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/movies/\(movieId)") else {
            completion(.failure(MovieServiceError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(MovieServiceError.noData))
                return
            }
            
            do {
                let movie = try JSONDecoder().decode(Movie.self, from: data)
                completion(.success(movie))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func getStreamingAvailability(movieId: Int, completion: @escaping (Result<[StreamingInfo], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/streaming/\(movieId)") else {
            completion(.failure(MovieServiceError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")
        
        print("🌐 Extension: Fetching streaming info for movie ID \(movieId)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Extension: Network error: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                print("❌ Extension: No data received")
                completion(.failure(MovieServiceError.noData))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                let backendResponse = try decoder.decode(BackendStreamingResponse.self, from: data)
                print("✅ Extension: Successfully fetched streaming info for movie ID \(movieId)")
                completion(.success(backendResponse.streamingOptions))
            } catch {
                print("❌ Extension: Decoding error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    func createMovieCard(movie: Movie, completion: @escaping (Result<MovieCard, Error>) -> Void) {
        getStreamingAvailability(movieId: movie.id) { result in
            switch result {
            case .success(let streamingInfo):
                let movieCard = MovieCard(
                    movie: movie,
                    streamingInfo: streamingInfo,
                    shareURL: "https://moviedrop.app/m/\(movie.id)",
                    createdAt: Date()
                )
                completion(.success(movieCard))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

enum MovieServiceError: Error {
    case invalidURL
    case noData
    case decodingError
}