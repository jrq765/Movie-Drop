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

struct StreamingInfo: Codable {
    let platform: String
    let type: StreamingType
    let url: String
    let price: String?
    
    enum StreamingType: String, Codable {
        case free = "free"
        case subscription = "subscription"
        case rent = "rent"
        case buy = "buy"
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
