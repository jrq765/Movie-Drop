import Foundation

// Seeded random number generator for consistent results
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: UInt64) {
        self.state = seed
    }
    
    mutating func next() -> UInt64 {
        state = state &* 1103515245 &+ 12345
        return state
    }
}

enum StreamingPlatform: String, CaseIterable, Identifiable {
    case netflix, prime, hulu, disney, hbo, apple, youtube, paramount, peacock
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .netflix: return "Netflix"
        case .prime: return "Prime Video"
        case .hulu: return "Hulu"
        case .disney: return "Disney+"
        case .hbo: return "Max"
        case .apple: return "Apple TV"
        case .youtube: return "YouTube Movies"
        case .paramount: return "Paramount+"
        case .peacock: return "Peacock"
        }
    }
    
    var iconName: String {
        switch self {
        case .netflix: return "play.rectangle.fill"
        case .prime: return "play.rectangle.fill"
        case .hulu: return "play.rectangle.fill"
        case .disney: return "play.rectangle.fill"
        case .hbo: return "play.rectangle.fill"
        case .apple: return "play.rectangle.fill"
        case .youtube: return "play.rectangle.fill"
        case .paramount: return "play.rectangle.fill"
        case .peacock: return "play.rectangle.fill"
        }
    }
}

class StreamingService: ObservableObject {
    private let baseURL: String = {
        if let url = Bundle.main.object(forInfoDictionaryKey: "MOVIEDROP_API_BASE_URL") as? String, !url.isEmpty {
            return url
        }
        // Fallback to canonical API if not set in Info.plist
        return "https://moviedrop.app/api"
    }()
    
    // MARK: - Streaming Platform URLs
    private let streamingPlatforms = [
        "netflix": "https://www.netflix.com/search?q=",
        "prime": "https://www.amazon.com/Prime-Video/b?node=2676882011&search=",
        "hulu": "https://www.hulu.com/search?q=",
        "disney": "https://www.disneyplus.com/search?q=",
        "hbo": "https://play.max.com/search?q=",
        "apple": "https://tv.apple.com/search?term=",
        "youtube": "https://www.youtube.com/results?search_query=",
        "paramount": "https://www.paramountplus.com/search?q=",
        "peacock": "https://www.peacocktv.com/search?q="
    ]
    
    // MARK: - Public Methods
    
    /// Get streaming URL for a specific platform and movie title
    func getStreamingURL(for platform: StreamingPlatform, movieTitle: String) -> URL? {
        guard let baseURL = streamingPlatforms[platform.rawValue] else { return nil }
        let encodedTitle = movieTitle.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "\(baseURL)\(encodedTitle)")
    }
    
    /// Fetch available platforms for a given movie from backend
    func getAvailablePlatforms(for movie: Movie) -> [StreamingPlatform] {
        // For now, return a more realistic subset based on movie characteristics
        // In the future, this could be replaced with real API data
        
        // Kick off background fetch to update cached availability if needed
        fetchAvailability(movieId: movie.id, movieTitle: movie.title)
        
        // Return cached data if available
        if let cached = cachedAvailability[movie.id] {
            return cached
        }
        
        // For now, return a smaller, more realistic set of platforms
        // This simulates that not all movies are available on all platforms
        let allPlatforms: [StreamingPlatform] = [.netflix, .prime, .apple, .hulu, .disney, .hbo, .youtube]
        
        // Use movie ID to consistently return the same platforms for the same movie
        let seed = movie.id % 7 // Use movie ID as seed for consistency
        let platformCount = 2 + (seed % 3) // Return 2-4 platforms
        
        // Shuffle platforms based on movie ID for consistency
        var generator = SeededRandomNumberGenerator(seed: UInt64(movie.id))
        let shuffledPlatforms = allPlatforms.shuffled(using: &generator)
        
        return Array(shuffledPlatforms.prefix(platformCount))
    }
    
    /// Published cache for UI updates
    @Published private(set) var streamingByMovieId: [Int: [StreamingInfo]] = [:]

    /// Get streaming info with direct links when available
    func getStreamingInfo(for movie: Movie) -> [StreamingInfo] {
        if let cached = streamingByMovieId[movie.id] { return cached }
        // Trigger fetch; return empty for first render (no placeholders)
        fetchAvailability(movieId: movie.id, movieTitle: movie.title)
        return []
    }

    // MARK: - Availability Cache
    private var cachedAvailability: [Int: [StreamingPlatform]] = [:]

    private func fetchAvailability(movieId: Int, movieTitle: String) {
        guard let url = URL(string: "\(baseURL)/streaming/\(movieId)?region=US") else { return }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            guard let self = self, let data = data else { return }
            
            // Handle local backend format
            struct LocalResponse: Decodable {
                let flatrate: [Provider]?
                let purchase: [Provider]?
            }
            struct Provider: Decodable {
                let provider_id: Int
                let provider_name: String
                let logo_path: String
                let display_priority: Int
                let kind: String?
            }
            
            if let resp = try? JSONDecoder().decode(LocalResponse.self, from: data) {
                var allProviders: [Provider] = []
                if let flatrate = resp.flatrate {
                    allProviders.append(contentsOf: flatrate.map { Provider(provider_id: $0.provider_id, provider_name: $0.provider_name, logo_path: $0.logo_path, display_priority: $0.display_priority, kind: "subscription") })
                }
                if let purchase = resp.purchase {
                    allProviders.append(contentsOf: purchase)
                }
                
                // Convert to StreamingInfo with direct URLs
                let streamingInfos: [StreamingInfo] = allProviders.compactMap { provider in
                    let directUrl = self.getDirectURL(for: provider.provider_id, movieTitle: movieTitle)
                    guard let url = directUrl else { return nil }
                    
                    return StreamingInfo(
                        platform: provider.provider_name,
                        type: provider.kind == "subscription" ? .subscription : .rent,
                        url: url.absoluteString,
                        price: provider.kind == "subscription" ? "Subscription" : "Rent/Buy"
                    )
                }
                
                if !streamingInfos.isEmpty {
                    DispatchQueue.main.async {
                        self.streamingByMovieId[movieId] = streamingInfos
                    }
                }
            }
        }.resume()
    }
    
    private func getDirectURL(for providerId: Int, movieTitle: String) -> URL? {
        let encodedTitle = movieTitle.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        switch providerId {
        case 8: return URL(string: "https://www.netflix.com/search?q=\(encodedTitle)")
        case 9, 10: return URL(string: "https://www.amazon.com/s?k=\(encodedTitle)&i=movies-tv")
        case 15: return URL(string: "https://www.hulu.com/search?q=\(encodedTitle)")
        case 337: return URL(string: "https://www.disneyplus.com/search?q=\(encodedTitle)")
        case 1899, 384: return URL(string: "https://play.max.com/search?q=\(encodedTitle)")
        case 2, 350: return URL(string: "https://tv.apple.com/search?term=\(encodedTitle)")
        case 192: return URL(string: "https://www.youtube.com/results?search_query=\(encodedTitle)+movie")
        case 531: return URL(string: "https://www.paramountplus.com/search?q=\(encodedTitle)")
        case 386, 387: return URL(string: "https://www.peacocktv.com/search?q=\(encodedTitle)")
        case 3: return URL(string: "https://play.google.com/store/search?q=\(encodedTitle)&c=movies")
        case 7: return URL(string: "https://www.vudu.com/content/movies/search?q=\(encodedTitle)")
        case 538: return URL(string: "https://watch.plex.tv/search?q=\(encodedTitle)")
        default: return nil
        }
    }
    
    func getPrice(for platform: StreamingPlatform) -> String? {
        switch platform {
        case .netflix, .hulu, .disney, .hbo, .paramount, .peacock:
            return "Subscription"
        case .prime:
            return "Prime Video"
        case .apple:
            return "Rent/Buy"
        case .youtube:
            return "Rent/Buy"
        }
    }
    
    private func getStreamingType(for platform: StreamingPlatform) -> StreamingInfo.StreamingType {
        switch platform {
        case .netflix, .hulu, .disney, .hbo, .paramount, .peacock, .prime:
            return .subscription
        case .apple, .youtube:
            return .rent
        }
    }
}