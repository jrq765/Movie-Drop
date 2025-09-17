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
    
    // Removed getAvailablePlatforms - only use real API data via getStreamingInfo
    
    /// Published cache for UI updates
    @Published private(set) var streamingByMovieId: [Int: [StreamingInfo]] = [:]
    
    /// Published cache for total counts
    @Published private(set) var streamingCountsByMovieId: [Int: (flatrate: Int, rent: Int, buy: Int)] = [:]
    
    
    /// Track fetch operations in progress to avoid duplicates
    private var fetchInProgress: Set<Int> = []

    /// Get streaming info with direct links when available - ONLY REAL DATA
    func getStreamingInfo(for movie: Movie) -> [StreamingInfo] {
        // Only return real cached data, never hardcoded fallbacks
        if let cached = streamingByMovieId[movie.id] { 
            print("🎬 StreamingService: Returning cached data for movie \(movie.id): \(cached.count) options")
            return cached 
        }
        
        // Trigger fetch if not already in progress
        if !fetchInProgress.contains(movie.id) {
            print("🎬 StreamingService: Starting fetch for movie \(movie.id)")
            fetchInProgress.insert(movie.id)
            fetchAvailability(movieId: movie.id, movieTitle: movie.title)
        } else {
            print("🎬 StreamingService: Fetch already in progress for movie \(movie.id)")
        }
        
        // Return empty array until real data arrives - NO FALLBACKS
        return []
    }
    
    /// Get total streaming options count for UI
    func getStreamingCount(for movie: Movie) -> Int {
        if let counts = streamingCountsByMovieId[movie.id] {
            return counts.flatrate + counts.rent + counts.buy
        }
        return 0
    }
    

    // MARK: - Availability Cache
    private var cachedAvailability: [Int: [StreamingPlatform]] = [:]

    private func fetchAvailability(movieId: Int, movieTitle: String) {
        // Fetch all types of streaming options (flatrate, rent, buy) - get comprehensive data
        guard let url = URL(string: "\(baseURL)/streaming/\(movieId)?region=US") else { return }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("🎬 StreamingService: Network error for movie \(movieId): \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("🎬 StreamingService: No data received for movie \(movieId)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🎬 StreamingService: HTTP \(httpResponse.statusCode) for movie \(movieId)")
            }
            
            // Handle new API format
            struct StreamingResponse: Decodable {
                let id: Int
                let title: String
                let year: Int
                let region: String
                let primary: ProviderInfo?
                let providers: [ProviderInfo]
                let counts: Counts
            }
            struct ProviderInfo: Decodable {
                let name: String
                let kind: String
                let url: String
                let logo_path: String?
                let provider_id: Int?
                let display_priority: Int?
            }
            struct Counts: Decodable {
                let flatrate: Int
                let rent: Int
                let buy: Int
            }
            
                    do {
                        let resp = try JSONDecoder().decode(StreamingResponse.self, from: data)
                        print("🎬 StreamingService: Fetched data for movie \(movieId)")
                        print("🎬 StreamingService: Primary provider: \(resp.primary?.name ?? "none")")
                        print("🎬 StreamingService: Total providers: \(resp.providers.count)")
                        print("🎬 StreamingService: Counts - flatrate: \(resp.counts.flatrate), rent: \(resp.counts.rent), buy: \(resp.counts.buy)")
                        
                        // Debug: Print all providers
                        for (index, provider) in resp.providers.enumerated() {
                            print("🎬 StreamingService: Provider \(index + 1): \(provider.name) - \(provider.url)")
                        }
                
                // Convert API providers directly to StreamingInfo (API already provides merged providers)
                let streamingInfos: [StreamingInfo] = resp.providers.compactMap { provider in
                    // Map API kind to StreamingType
                    let streamingType: StreamingInfo.StreamingType
                    let priceText: String
                    
                    switch provider.kind {
                    case "flatrate":
                        streamingType = .subscription
                        priceText = "Subscription"
                    case "rent/buy":
                        streamingType = StreamingInfo.StreamingType.rentBuy
                        priceText = "Rent/Buy"
                    case "rent":
                        streamingType = .rent
                        priceText = "Rent"
                    case "buy":
                        streamingType = .buy
                        priceText = "Buy"
                    default:
                        streamingType = .subscription
                        priceText = "Available"
                    }
                    
                    return StreamingInfo(
                        platform: provider.name,
                        type: streamingType,
                        url: provider.url,
                        price: priceText,
                        providerId: provider.provider_id,
                        logoPath: provider.logo_path,
                        displayPriority: provider.display_priority,
                        kind: provider.kind
                    )
                }
                
                // Sort by display_priority (ascending) then by type priority (flatrate > rent > buy)
                let sortedStreamingInfos = streamingInfos.sorted { first, second in
                    // First sort by display_priority
                    if let firstPriority = first.displayPriority, let secondPriority = second.displayPriority {
                        if firstPriority != secondPriority {
                            return firstPriority < secondPriority
                        }
                    }
                    
                    // Then sort by type priority
                    let typePriority: [StreamingInfo.StreamingType: Int] = [
                        .subscription: 1,
                        StreamingInfo.StreamingType.rentBuy: 2,
                        .rent: 3,
                        .buy: 4,
                        .free: 5
                    ]
                    
                    let firstTypePriority = typePriority[first.type] ?? 6
                    let secondTypePriority = typePriority[second.type] ?? 6
                    
                    return firstTypePriority < secondTypePriority
                }
                
                print("🎬 StreamingService: Final streaming infos: \(sortedStreamingInfos.count)")
                
                DispatchQueue.main.async {
                    // Remove from fetch progress
                    self.fetchInProgress.remove(movieId)
                    
                    if !sortedStreamingInfos.isEmpty {
                        print("🎬 StreamingService: Updating cache for movie \(movieId) with \(sortedStreamingInfos.count) streaming options")
                        self.streamingByMovieId[movieId] = sortedStreamingInfos
                        self.streamingCountsByMovieId[movieId] = (flatrate: resp.counts.flatrate, rent: resp.counts.rent, buy: resp.counts.buy)
                        print("🎬 StreamingService: Cache updated. Total cached movies: \(self.streamingByMovieId.keys.count)")
                    } else {
                        print("🎬 StreamingService: No streaming options found for movie \(movieId)")
                        // Cache empty result to avoid repeated requests
                        self.streamingByMovieId[movieId] = []
                        self.streamingCountsByMovieId[movieId] = (flatrate: 0, rent: 0, buy: 0)
                    }
                }
            } catch {
                print("🎬 StreamingService: JSON decode error for movie \(movieId): \(error)")
                if let dataString = String(data: data, encoding: .utf8) {
                    print("🎬 StreamingService: Raw response: \(dataString)")
                }
                DispatchQueue.main.async {
                    // Remove from fetch progress on error
                    self.fetchInProgress.remove(movieId)
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