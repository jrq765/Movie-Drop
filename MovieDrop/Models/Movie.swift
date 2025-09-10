import Foundation

struct Movie: Identifiable, Codable {
    let id: Int
    let title: String
    let overview: String?
    let posterPath: String?
    let releaseDate: String?
    let voteAverage: Double?
    let voteCount: Int?
    let adult: Bool?
    let backdropPath: String?
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
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case adult
        case backdropPath = "backdrop_path"
        case genreIds = "genre_ids"
        case originalLanguage = "original_language"
        case originalTitle = "original_title"
        case popularity
        case video
    }

    // Support decoding from both snake_case (TMDB) and camelCase (our backend)
    private enum CamelKeys: String, CodingKey {
        case posterPath
        case releaseDate
        case voteAverage
        case voteCount
        case backdropPath
        case genreIds
        case originalLanguage
        case originalTitle
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let camel = try? decoder.container(keyedBy: CamelKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        overview = try container.decodeIfPresent(String.self, forKey: .overview)
        posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath) ?? camel?.decodeIfPresent(String.self, forKey: .posterPath)
        releaseDate = try container.decodeIfPresent(String.self, forKey: .releaseDate) ?? camel?.decodeIfPresent(String.self, forKey: .releaseDate)
        voteAverage = try container.decodeIfPresent(Double.self, forKey: .voteAverage) ?? camel?.decodeIfPresent(Double.self, forKey: .voteAverage)
        voteCount = try container.decodeIfPresent(Int.self, forKey: .voteCount) ?? camel?.decodeIfPresent(Int.self, forKey: .voteCount)
        adult = try container.decodeIfPresent(Bool.self, forKey: .adult)
        backdropPath = try container.decodeIfPresent(String.self, forKey: .backdropPath) ?? camel?.decodeIfPresent(String.self, forKey: .backdropPath)
        genreIds = try container.decodeIfPresent([Int].self, forKey: .genreIds) ?? camel?.decodeIfPresent([Int].self, forKey: .genreIds)
        originalLanguage = try container.decodeIfPresent(String.self, forKey: .originalLanguage) ?? camel?.decodeIfPresent(String.self, forKey: .originalLanguage)
        originalTitle = try container.decodeIfPresent(String.self, forKey: .originalTitle) ?? camel?.decodeIfPresent(String.self, forKey: .originalTitle)
        popularity = try container.decodeIfPresent(Double.self, forKey: .popularity)
        video = try container.decodeIfPresent(Bool.self, forKey: .video)
    }

    // MARK: - Computed URLs
    var posterURL: URL? {
        guard let posterPath = posterPath, !posterPath.isEmpty else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w342\(posterPath)")
    }
    
    var backdropURL: URL? {
        guard let backdropPath = backdropPath, !backdropPath.isEmpty else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w780\(backdropPath)")
    }
}

struct MovieResponse: Codable {
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
    
    enum StreamingType: String, Codable {
        case free = "free"
        case subscription = "subscription"
        case rent = "rent"
        case buy = "buy"
    }
}