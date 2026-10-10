import Foundation

public struct ChannelItem: Identifiable, Codable, Hashable {
    public var id: Int64
    public var playlistId: Int64
    public var name: String
    public var streamUrl: String
    public var logoUrl: String?
    public var groupTitle: String
    public var streamType: String // "LIVE", "MOVIE", "SERIES", "PVR"
    public var tvgId: String?
    public var tvgName: String?
    public var currentProgram: String?
    public var programTime: String?
    public var quality: String // "1080p", "4K", "HDR", "720p"
    public var isFavorite: Bool
    public var lastPlayedTimestamp: Int64
    public var posterUrl: String?
    public var playbackPositionMs: Int64
    public var durationMs: Int64

    public init(
        id: Int64 = Int64(Date().timeIntervalSince1970 * 1000) + Int64.random(in: 1...999),
        playlistId: Int64 = 0,
        name: String,
        streamUrl: String,
        logoUrl: String? = nil,
        groupTitle: String = "Genel",
        streamType: String = "LIVE",
        tvgId: String? = nil,
        tvgName: String? = nil,
        currentProgram: String? = nil,
        programTime: String? = nil,
        quality: String = "1080p",
        isFavorite: Bool = false,
        lastPlayedTimestamp: Int64 = 0,
        posterUrl: String? = nil,
        playbackPositionMs: Int64 = 0,
        durationMs: Int64 = 0
    ) {
        self.id = id
        self.playlistId = playlistId
        self.name = name
        self.streamUrl = streamUrl
        self.logoUrl = logoUrl
        self.groupTitle = groupTitle
        self.streamType = streamType
        self.tvgId = tvgId
        self.tvgName = tvgName
        self.currentProgram = currentProgram
        self.programTime = programTime
        self.quality = quality
        self.isFavorite = isFavorite
        self.lastPlayedTimestamp = lastPlayedTimestamp
        self.posterUrl = posterUrl
        self.playbackPositionMs = playbackPositionMs
        self.durationMs = durationMs
    }
}
