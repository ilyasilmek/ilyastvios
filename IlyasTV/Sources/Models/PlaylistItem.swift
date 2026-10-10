import Foundation

public struct PlaylistItem: Identifiable, Codable, Hashable {
    public var id: Int64
    public var name: String
    public var urlOrPath: String
    public var isLocalFile: Bool
    public var channelCount: Int
    public var liveCount: Int
    public var movieCount: Int
    public var seriesCount: Int
    public var username: String?
    public var serverHost: String?
    public var status: String? // "Aktif", "Pasif", "Süresi Doldu", "Bilinmiyor"
    public var expDateTimestamp: Int64? // Unix timestamp in milliseconds
    public var maxConnections: String?
    public var activeConnections: String?
    public var isTrial: Bool
    public var createdAt: Int64

    public init(
        id: Int64 = Int64(Date().timeIntervalSince1970 * 1000) + Int64.random(in: 1...999),
        name: String,
        urlOrPath: String,
        isLocalFile: Bool = false,
        channelCount: Int = 0,
        liveCount: Int = 0,
        movieCount: Int = 0,
        seriesCount: Int = 0,
        username: String? = nil,
        serverHost: String? = nil,
        status: String? = "Aktif",
        expDateTimestamp: Int64? = nil,
        maxConnections: String? = "1",
        activeConnections: String? = "1",
        isTrial: Bool = false,
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.name = name
        self.urlOrPath = urlOrPath
        self.isLocalFile = isLocalFile
        self.channelCount = channelCount
        self.liveCount = liveCount
        self.movieCount = movieCount
        self.seriesCount = seriesCount
        self.username = username
        self.serverHost = serverHost
        self.status = status
        self.expDateTimestamp = expDateTimestamp
        self.maxConnections = maxConnections
        self.activeConnections = activeConnections
        self.isTrial = isTrial
        self.createdAt = createdAt
    }
}
