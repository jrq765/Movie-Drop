import Foundation

class StreamingService: ObservableObject {
    
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
        let encodedTitle = movieTitle.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? movieTitle
        let baseURL = streamingPlatforms[platform.rawValue] ?? ""
        let fullURL = baseURL + encodedTitle
        
        return URL(string: fullURL)
    }
    
    /// Get all available streaming platforms for a movie
    func getAvailablePlatforms(for movie: Movie) -> [StreamingPlatform] {
        // For now, return a mock list of available platforms
        // In a real app, this would query JustWatch API or similar service
        return [.netflix, .prime, .apple, .hulu]
    }
    
    /// Get streaming info with affiliate links
    func getStreamingInfo(for movie: Movie) -> [StreamingInfo] {
        let platforms = getAvailablePlatforms(for: movie)
        
        return platforms.map { platform in
            let url = getStreamingURL(for: platform, movieTitle: movie.title)
            return StreamingInfo(
                platform: platform.displayName,
                type: getStreamingType(for: platform),
                url: url?.absoluteString ?? "",
                price: getPrice(for: platform),
                providerId: nil,
                logoPath: nil,
                displayPriority: nil,
                kind: nil
            )
        }
    }
    
    // MARK: - Private Methods
    
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
        case .netflix, .hulu, .disney, .hbo, .paramount, .peacock:
            return .subscription
        case .prime:
            return .subscription
        case .apple, .youtube:
            return .rent
        }
    }
}

// MARK: - Streaming Platform Enum

enum StreamingPlatform: String, CaseIterable {
    case netflix = "netflix"
    case prime = "prime"
    case hulu = "hulu"
    case disney = "disney"
    case hbo = "hbo"
    case apple = "apple"
    case youtube = "youtube"
    case paramount = "paramount"
    case peacock = "peacock"
    
    var displayName: String {
        switch self {
        case .netflix:
            return "Netflix"
        case .prime:
            return "Prime Video"
        case .hulu:
            return "Hulu"
        case .disney:
            return "Disney+"
        case .hbo:
            return "Max"
        case .apple:
            return "Apple TV+"
        case .youtube:
            return "YouTube Movies"
        case .paramount:
            return "Paramount+"
        case .peacock:
            return "Peacock"
        }
    }
    
    var iconName: String {
        switch self {
        case .netflix:
            return "tv.fill"
        case .prime:
            return "play.rectangle.fill"
        case .hulu:
            return "tv.circle.fill"
        case .disney:
            return "star.fill"
        case .hbo:
            return "tv.fill"
        case .apple:
            return "applelogo"
        case .youtube:
            return "play.rectangle.fill"
        case .paramount:
            return "tv.fill"
        case .peacock:
            return "tv.fill"
        }
    }
    
    var color: String {
        switch self {
        case .netflix:
            return "red"
        case .prime:
            return "blue"
        case .hulu:
            return "green"
        case .disney:
            return "blue"
        case .hbo:
            return "purple"
        case .apple:
            return "gray"
        case .youtube:
            return "red"
        case .paramount:
            return "blue"
        case .peacock:
            return "blue"
        }
    }
}
