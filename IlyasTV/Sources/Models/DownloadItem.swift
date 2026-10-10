import Foundation

public enum DownloadStatus: String, Codable, Hashable {
    case pending = "PENDING"
    case downloading = "DOWNLOADING"
    case paused = "PAUSED"
    case completed = "COMPLETED"
    case failed = "FAILED"
    case cancelled = "CANCELLED"
}

public struct DownloadItem: Identifiable, Codable, Hashable {
    public var id: Int64
    public var channelId: Int64
    public var title: String
    public var streamUrl: String
    public var localFilePath: String?
    public var posterUrl: String?
    public var groupTitle: String
    public var streamType: String // "MOVIE", "SERIES", "PVR", "VOD"
    public var status: DownloadStatus
    public var progressPercent: Int
    public var bytesDownloaded: Int64
    public var totalBytes: Int64
    public var errorMessage: String?
    public var createdAt: Int64
    public var completedAt: Int64

    public init(
        id: Int64 = Int64(Date().timeIntervalSince1970 * 1000) + Int64.random(in: 1...999),
        channelId: Int64 = 0,
        title: String,
        streamUrl: String,
        localFilePath: String? = nil,
        posterUrl: String? = nil,
        groupTitle: String = "Genel",
        streamType: String = "MOVIE",
        status: DownloadStatus = .pending,
        progressPercent: Int = 0,
        bytesDownloaded: Int64 = 0,
        totalBytes: Int64 = 0,
        errorMessage: String? = nil,
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        completedAt: Int64 = 0
    ) {
        self.id = id
        self.channelId = channelId
        self.title = title
        self.streamUrl = streamUrl
        self.localFilePath = localFilePath
        self.posterUrl = posterUrl
        self.groupTitle = groupTitle
        self.streamType = streamType
        self.status = status
        self.progressPercent = progressPercent
        self.bytesDownloaded = bytesDownloaded
        self.totalBytes = totalBytes
        self.errorMessage = errorMessage
        self.createdAt = createdAt
        self.completedAt = completedAt
    }

    public func toChannelItem() -> ChannelItem {
        return ChannelItem(
            id: channelId > 0 ? channelId : id,
            name: title,
            streamUrl: localFilePath ?? streamUrl,
            logoUrl: posterUrl,
            groupTitle: groupTitle,
            streamType: streamType,
            quality: "İndirilen Dosya",
            isFavorite: false,
            posterUrl: posterUrl
        )
    }
}
