import Foundation

public struct SubtitleItem: Identifiable, Codable, Hashable {
    public var id: String
    public var title: String
    public var language: String
    public var languageCode: String
    public var downloadUrl: String
    public var sourceName: String
    public var rating: String?
    public var isHearingImpaired: Bool

    public init(
        id: String,
        title: String,
        language: String,
        languageCode: String,
        downloadUrl: String,
        sourceName: String = "SubDL Multi-Source",
        rating: String? = nil,
        isHearingImpaired: Bool = false
    ) {
        self.id = id
        self.title = title
        self.language = language
        self.languageCode = languageCode
        self.downloadUrl = downloadUrl
        self.sourceName = sourceName
        self.rating = rating
        self.isHearingImpaired = isHearingImpaired
    }
}
