import Foundation

struct Movie: Identifiable, Codable {
    let id: Int
    let title: String
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let voteAverage: Double?
    let voteCount: Int?
    let adult: Bool?
    let genreIds: [Int]?
    let originalLanguage: String?
    let originalTitle: String?
    let popularity: Double?
    let video: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case adult
        case genreIds = "genre_ids"
        case originalLanguage = "original_language"
        case originalTitle = "original_title"
        case popularity
        case video
    }
    
    var posterURL: URL? {
        guard let posterPath = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
    }
    
    var backdropURL: URL? {
        guard let backdropPath = backdropPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w1280\(backdropPath)")
    }
    
    var formattedReleaseDate: String? {
        guard let releaseDate = releaseDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let date = formatter.date(from: releaseDate) {
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
        return releaseDate
    }
}

struct MovieResponse: Codable {
    let results: [Movie]
    let page: Int
    let totalPages: Int
    let totalResults: Int
}

struct BackendMovieResponse: Codable {
    let movies: [Movie]
    let page: Int
    let totalPages: Int
    let totalResults: Int
}

struct TMDBMovieResponse: Codable {
    let page: Int
    let results: [Movie]
    let totalPages: Int
    let totalResults: Int
    
    enum CodingKeys: String, CodingKey {
        case page
        case results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

struct StreamingInfo: Codable {
    let platform: String
    let type: StreamingType
    let url: String
    let price: String?
    
    // New fields from API response
    let providerId: Int?
    let logoPath: String?
    let displayPriority: Int?
    let kind: String?
    
    // Custom initializer
    init(platform: String, type: StreamingType, url: String, price: String?, providerId: Int?, logoPath: String?, displayPriority: Int?, kind: String?) {
        self.platform = platform
        self.type = type
        self.url = url
        self.price = price
        self.providerId = providerId
        self.logoPath = logoPath
        self.displayPriority = displayPriority
        self.kind = kind
    }
    
    enum CodingKeys: String, CodingKey {
        case platform, type, url, price
        case providerId = "provider_id"
        case logoPath = "logo_path"
        case displayPriority = "display_priority"
        case kind
    }
    
    enum StreamingType: String, Codable {
        case free = "free"
        case subscription = "subscription"
        case rent = "rent"
        case buy = "buy"
        case rentBuy = "rent/buy"
        case flatrate = "flatrate"
    }
}

struct MovieCard: Codable {
    let movie: Movie
    let streamingInfo: [StreamingInfo]
    let shareURL: String
    let createdAt: Date
}

// MARK: - Backend Streaming Response
struct BackendStreamingResponse: Codable {
    let movieId: Int
    let title: String
    let streamingOptions: [StreamingInfo]

    enum CodingKeys: String, CodingKey {
        case movieId = "movie_id"
        case title
        case streamingOptions = "streaming_options"
    }
}
