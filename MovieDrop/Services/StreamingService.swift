import Foundation

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
    private let baseURL = "http://127.0.0.1:3000/api"
    
    // MARK: - Streaming Platform URLs
    private let streamingPlatforms = [
        "netflix": "https://www.netflix.com/search?q=",
        "prime": "https://www.amazon.com/s?k=",
        "hulu": "https://www.hulu.com/search?q=",
        "disney": "https://www.disneyplus.com/search?q=",
        "hbo": "https://play.max.com/search?q=",
        "apple": "https://tv.apple.com/search?q=",
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
        // Synchronous wrapper for now to keep interface; fall back to broad list until request completes
        // Kick off background fetch to update cached availability if needed
        fetchAvailability(movieId: movie.id)
        return cachedAvailability[movie.id] ?? [.netflix, .prime, .apple, .hulu]
    }
    
    /// Get streaming info with affiliate links for only available platforms
    func getStreamingInfo(for movie: Movie) -> [StreamingInfo] {
        let platforms = getAvailablePlatforms(for: movie)
        return platforms.compactMap { platform in
            guard let url = getStreamingURL(for: platform, movieTitle: movie.title) else { return nil }
            return StreamingInfo(
                platform: platform.displayName,
                type: getStreamingType(for: platform),
                url: url.absoluteString,
                price: getPrice(for: platform)
            )
        }
    }

    // MARK: - Availability Cache
    private var cachedAvailability: [Int: [StreamingPlatform]] = [:]

    private func fetchAvailability(movieId: Int) {
        guard let url = URL(string: "\(baseURL)/streaming/\(movieId)") else { return }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            guard let self = self, let data = data else { return }
            struct Response: Decodable { let streamingOptions: [Option] }
            struct Option: Decodable { let platformId: String?; let platform: String? }
            if let resp = try? JSONDecoder().decode(Response.self, from: data) {
                let platforms: [StreamingPlatform] = resp.streamingOptions.compactMap { opt in
                    if let id = opt.platformId, let p = StreamingPlatform(rawValue: id) { return p }
                    // fallback by name mapping
                    switch (opt.platform ?? "").lowercased() {
                    case "netflix": return .netflix
                    case "amazon prime video", "prime": return .prime
                    case "hulu": return .hulu
                    case "disney+", "disney": return .disney
                    case "max", "hbo": return .hbo
                    case "apple tv", "apple": return .apple
                    case "youtube", "youtube movies": return .youtube
                    case "paramount+", "paramount": return .paramount
                    case "peacock": return .peacock
                    default: return nil
                    }
                }
                if !platforms.isEmpty {
                    self.cachedAvailability[movieId] = platforms
                }
            }
        }.resume()
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