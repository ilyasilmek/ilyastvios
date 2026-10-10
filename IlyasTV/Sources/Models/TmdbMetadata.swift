import Foundation

public struct TmdbMetadata: Codable, Hashable {
    public var title: String
    public var originalTitle: String?
    public var overview: String?
    public var posterUrl: String?
    public var backdropUrl: String?
    public var rating: Double
    public var voteCount: Int
    public var releaseYear: String?
    public var genres: [String]
    public var tmdbId: Int64?
    public var trailerUrl: String?

    public init(
        title: String,
        originalTitle: String? = nil,
        overview: String? = nil,
        posterUrl: String? = nil,
        backdropUrl: String? = nil,
        rating: Double = 0.0,
        voteCount: Int = 0,
        releaseYear: String? = nil,
        genres: [String] = [],
        tmdbId: Int64? = nil,
        trailerUrl: String? = nil
    ) {
        self.title = title
        self.originalTitle = originalTitle
        self.overview = overview
        self.posterUrl = posterUrl
        self.backdropUrl = backdropUrl
        self.rating = rating
        self.voteCount = voteCount
        self.releaseYear = releaseYear
        self.genres = genres
        self.tmdbId = tmdbId
        self.trailerUrl = trailerUrl
    }
}
