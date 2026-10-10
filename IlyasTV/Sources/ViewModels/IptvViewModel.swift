import Foundation
import Combine
import SwiftUI

public enum ImportState: Equatable {
    case idle
    case loading
    case success(message: String, accountInfo: AccountInfo?)
    case error(message: String)
}

@MainActor
public final class IptvViewModel: ObservableObject {
    private let storage = StorageManager.shared
    private let pvrService = PvrService.shared
    private let downloadService = DownloadService.shared
    private var cancellables = Set<AnyCancellable>()

    // App Preferences
    @AppStorage("disclaimer_accepted") public var hasAcceptedDisclaimer: Bool = false
    @AppStorage("app_view_mode") public var viewMode: ViewModeSetting = .grid
    @AppStorage("app_buffer_setting") public var bufferSetting: BufferOption = .normal
    @AppStorage("app_brand_style") public var brandStyle: ThemeBrandStyle = .sinema
    @AppStorage("tmdb_api_key") public var tmdbApiKey: String = "" {
        didSet {
            Task {
                await TmdbService.shared.setApiKey(tmdbApiKey)
            }
        }
    }

    // Published State
    @Published public var channels: [ChannelItem] = []
    @Published public var playlists: [PlaylistItem] = []
    @Published public var downloads: [DownloadItem] = []
    @Published public var searchHistory: [String] = []

    @Published public var selectedPlaylistId: Int64? = nil
    @Published public var selectedLiveCategory: String = "Tümü"
    @Published public var selectedMovieCategory: String = "Tümü"
    @Published public var selectedSeriesCategory: String = "Tümü"

    @Published public var searchQuery: String = ""
    @Published public var currentlyPlayingChannel: ChannelItem? = nil
    @Published public var importState: ImportState = .idle
    @Published public var toastMessage: String? = nil

    @Published public var pvrRecordingState = PvrRecordingState()

    public init() {
        bindStorage()
        if !tmdbApiKey.isEmpty {
            Task {
                await TmdbService.shared.setApiKey(tmdbApiKey)
            }
        }
    }

    private func bindStorage() {
        storage.$channels
            .receive(on: DispatchQueue.main)
            .assign(to: \.channels, on: self)
            .store(in: &cancellables)

        storage.$playlists
            .receive(on: DispatchQueue.main)
            .assign(to: \.playlists, on: self)
            .store(in: &cancellables)

        storage.$downloads
            .receive(on: DispatchQueue.main)
            .assign(to: \.downloads, on: self)
            .store(in: &cancellables)

        storage.$searchHistory
            .receive(on: DispatchQueue.main)
            .assign(to: \.searchHistory, on: self)
            .store(in: &cancellables)

        pvrService.$recordingState
            .receive(on: DispatchQueue.main)
            .assign(to: \.pvrRecordingState, on: self)
            .store(in: &cancellables)
    }

    // MARK: - Computed Properties for Streams
    public var liveChannels: [ChannelItem] {
        channels.filter { $0.streamType == "LIVE" }
    }

    public var movieChannels: [ChannelItem] {
        channels.filter { $0.streamType == "MOVIE" }
    }

    public var seriesChannels: [ChannelItem] {
        channels.filter { $0.streamType == "SERIES" }
    }

    public var favoriteChannels: [ChannelItem] {
        channels.filter { $0.isFavorite }
    }

    public var recentChannels: [ChannelItem] {
        channels.filter { $0.lastPlayedTimestamp > 0 }
            .sorted { $0.lastPlayedTimestamp > $1.lastPlayedTimestamp }
    }

    public var continueWatchingList: [ChannelItem] {
        channels.filter { $0.playbackPositionMs > 0 && ($0.streamType == "MOVIE" || $0.streamType == "SERIES") }
            .sorted { $0.lastPlayedTimestamp > $1.lastPlayedTimestamp }
    }

    public var watchHistoryList: [ChannelItem] {
        recentChannels
    }

    public var liveCategories: [String] {
        var cats = Array(Set(liveChannels.map { $0.groupTitle })).sorted()
        cats.removeAll { $0 == "Genel" }
        return ["Tümü", "Favoriler"] + (cats.contains("Ulusal Kanallar") ? ["Ulusal Kanallar"] + cats.filter { $0 != "Ulusal Kanallar" } : cats)
    }

    public var movieCategories: [String] {
        let cats = Array(Set(movieChannels.map { $0.groupTitle })).sorted()
        return ["Tümü", "Favoriler"] + cats
    }

    public var seriesCategories: [String] {
        let cats = Array(Set(seriesChannels.map { $0.groupTitle })).sorted()
        return ["Tümü", "Favoriler"] + cats
    }

    public var filteredLiveChannels: [ChannelItem] {
        filterChannels(liveChannels, category: selectedLiveCategory)
    }

    public var filteredMovieChannels: [ChannelItem] {
        filterChannels(movieChannels, category: selectedMovieCategory)
    }

    public var filteredSeriesChannels: [ChannelItem] {
        filterChannels(seriesChannels, category: selectedSeriesCategory)
    }

    private func filterChannels(_ list: [ChannelItem], category: String) -> [ChannelItem] {
        switch category {
        case "Tümü", "All": return list
        case "Favoriler", "Favorites": return list.filter { $0.isFavorite }
        default: return list.filter { $0.groupTitle.caseInsensitiveCompare(category) == .orderedSame }
        }
    }

    public var globalSearchResults: [ChannelItem] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return [] }
        return channels.filter {
            $0.name.lowercased().contains(query) ||
            $0.groupTitle.lowercased().contains(query)
        }
    }

    public var latestAccountInfo: AccountInfo? {
        guard let latest = playlists.first else { return nil }
        return AccountInfo(
            username: latest.username ?? (latest.isLocalFile ? "Yerel M3U Dosyası" : "IPTV Hesabı"),
            serverHost: latest.serverHost ?? latest.name,
            status: latest.status ?? "Aktif",
            expDateTimestamp: latest.expDateTimestamp,
            maxConnections: latest.maxConnections ?? "1",
            activeConnections: latest.activeConnections ?? "1",
            isTrial: latest.isTrial
        )
    }

    // MARK: - Playback Actions
    public func playChannel(_ channel: ChannelItem) {
        currentlyPlayingChannel = channel
        storage.recordChannelPlayed(channelId: channel.id)
    }

    public func stopPlayback() {
        currentlyPlayingChannel = nil
    }

    public func playNextChannel() {
        guard let current = currentlyPlayingChannel else { return }
        let list: [ChannelItem]
        switch current.streamType {
        case "MOVIE": list = filteredMovieChannels.isEmpty ? movieChannels : filteredMovieChannels
        case "SERIES": list = filteredSeriesChannels.isEmpty ? seriesChannels : filteredSeriesChannels
        default: list = filteredLiveChannels.isEmpty ? liveChannels : filteredLiveChannels
        }
        guard let idx = list.firstIndex(where: { $0.id == current.id }), !list.isEmpty else { return }
        let nextIndex = (idx + 1) % list.count
        playChannel(list[nextIndex])
    }

    public func playPreviousChannel() {
        guard let current = currentlyPlayingChannel else { return }
        let list: [ChannelItem]
        switch current.streamType {
        case "MOVIE": list = filteredMovieChannels.isEmpty ? movieChannels : filteredMovieChannels
        case "SERIES": list = filteredSeriesChannels.isEmpty ? seriesChannels : filteredSeriesChannels
        default: list = filteredLiveChannels.isEmpty ? liveChannels : filteredLiveChannels
        }
        guard let idx = list.firstIndex(where: { $0.id == current.id }), !list.isEmpty else { return }
        let prevIndex = idx - 1 < 0 ? list.count - 1 : idx - 1
        playChannel(list[prevIndex])
    }

    public func toggleFavorite(_ channel: ChannelItem) {
        storage.toggleFavorite(channelId: channel.id)
        if currentlyPlayingChannel?.id == channel.id {
            currentlyPlayingChannel?.isFavorite.toggle()
        }
    }

    public func updatePlaybackProgress(channelId: Int64, positionMs: Int64, durationMs: Int64) {
        storage.updatePlaybackProgress(channelId: channelId, positionMs: positionMs, durationMs: durationMs)
    }

    public func resetPlaybackProgress(channelId: Int64) {
        storage.resetPlaybackProgress(channelId: channelId)
    }

    public func removeFromWatchHistory(channelId: Int64) {
        storage.removeFromWatchHistory(channelId: channelId)
    }

    public func moveWatchHistoryToTop(channelId: Int64) {
        storage.moveWatchHistoryToTop(channelId: channelId)
    }

    // MARK: - Playlist Imports
    public func importPlaylistFromUrl(name: String, url: String) {
        let cleanUrl = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanUrl.isEmpty else {
            importState = .error(message: "Lütfen geçerli bir M3U veya Xtream linki girin.")
            return
        }

        importState = .loading
        Task {
            do {
                let parseResult = try await M3uParser.parse(from: cleanUrl)
                let channels = parseResult.channels
                guard !channels.isEmpty else {
                    importState = .error(message: "M3U linkinde geçerli kanal bulunamadı.")
                    return
                }

                let liveCount = channels.filter { $0.streamType == "LIVE" }.count
                let movieCount = channels.filter { $0.streamType == "MOVIE" }.count
                let seriesCount = channels.filter { $0.streamType == "SERIES" }.count
                let acc = parseResult.accountInfo

                let playlistName = name.isEmpty ? (acc.username.map { "\($0) IPTV Listesi" } ?? "IPTV Kanal Listesi") : name
                let playlist = PlaylistItem(
                    name: playlistName,
                    urlOrPath: cleanUrl,
                    isLocalFile: false,
                    channelCount: channels.count,
                    liveCount: liveCount,
                    movieCount: movieCount,
                    seriesCount: seriesCount,
                    username: acc.username,
                    serverHost: acc.serverHost,
                    status: acc.status,
                    expDateTimestamp: acc.expDateTimestamp,
                    maxConnections: acc.maxConnections,
                    activeConnections: acc.activeConnections,
                    isTrial: acc.isTrial
                )

                let channelsWithPlaylist = channels.map {
                    var ch = $0
                    ch.playlistId = playlist.id
                    return ch
                }

                storage.addPlaylist(playlist, newChannels: channelsWithPlaylist)
                importState = .success(
                    message: "Hesap ve oynatma listesi başarıyla bağlandı! Toplam \(channels.count) içerik yüklendi.",
                    accountInfo: acc
                )
            } catch {
                importState = .error(message: error.localizedDescription)
            }
        }
    }

    public func importXtreamAccount(server: String, user: String, pass: String) {
        let cleanServer = server.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanUser = user.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPass = pass.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanServer.isEmpty, !cleanUser.isEmpty, !cleanPass.isEmpty else {
            importState = .error(message: "Lütfen sunucu adresi, kullanıcı adı ve şifreyi eksiksiz girin.")
            return
        }

        let formattedServer = (!cleanServer.hasPrefix("http://") && !cleanServer.hasPrefix("https://")) ? "http://\(cleanServer)" : cleanServer
        let noSlashServer = formattedServer.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let m3uUrl = "\(noSlashServer)/get.php?username=\(cleanUser)&password=\(cleanPass)&type=m3u_plus&output=ts"

        importPlaylistFromUrl(name: cleanUser, url: m3uUrl)
    }

    public func importPlaylistContent(name: String, content: String, isFile: Bool = true) {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            importState = .error(message: "Dosya veya metin içeriği boş.")
            return
        }

        importState = .loading
        Task {
            let parseResult = await M3uParser.parse(content: content)
            let channels = parseResult.channels
            guard !channels.isEmpty else {
                importState = .error(message: "M3U dosyasında geçerli kanal bulunamadı.")
                return
            }

            let liveCount = channels.filter { $0.streamType == "LIVE" }.count
            let movieCount = channels.filter { $0.streamType == "MOVIE" }.count
            let seriesCount = channels.filter { $0.streamType == "SERIES" }.count
            let acc = parseResult.accountInfo

            let playlistName = name.isEmpty ? (isFile ? "Yüklenen M3U Dosyası" : "Yapıştırılan M3U") : name
            let playlist = PlaylistItem(
                name: playlistName,
                urlOrPath: isFile ? "Yerel Dosya" : "Metin İçeriği",
                isLocalFile: isFile,
                channelCount: channels.count,
                liveCount: liveCount,
                movieCount: movieCount,
                seriesCount: seriesCount,
                username: acc.username,
                serverHost: acc.serverHost,
                status: acc.status,
                expDateTimestamp: acc.expDateTimestamp,
                maxConnections: acc.maxConnections,
                activeConnections: acc.activeConnections,
                isTrial: acc.isTrial
            )

            let channelsWithPlaylist = channels.map {
                var ch = $0
                ch.playlistId = playlist.id
                return ch
            }

            storage.addPlaylist(playlist, newChannels: channelsWithPlaylist)
            importState = .success(
                message: "M3U dosyası yüklendi! Toplam \(channels.count) içerik eklendi.",
                accountInfo: acc
            )
        }
    }

    public func deletePlaylist(id: Int64) {
        storage.deletePlaylist(id: id)
        if selectedPlaylistId == id {
            selectedPlaylistId = nil
        }
    }

    public func refreshPlaylist(playlistId: Int64) {
        guard let playlist = playlists.first(where: { $0.id == playlistId }) else { return }
        if playlist.isLocalFile || !playlist.urlOrPath.lowercased().hasPrefix("http") {
            importState = .error(message: "Yerel dosya kaynakları yalnızca yeni dosya seçilerek güncellenebilir.")
            return
        }
        importPlaylistFromUrl(name: playlist.name, url: playlist.urlOrPath)
    }

    // MARK: - Downloads & PVR
    public func downloadChannel(_ channel: ChannelItem) {
        if channel.streamType == "LIVE" {
            toastMessage = "Canlı TV yayınları için PVR kayıt özelliğini kullanabilirsiniz."
            return
        }

        if let existing = downloads.first(where: { $0.channelId == channel.id }), existing.status == .completed {
            toastMessage = "✅ “\(channel.name)” zaten cihazınızda indirilmiş."
            return
        }

        _ = downloadService.startDownload(channel: channel)
        toastMessage = "⬇️ “\(channel.name)” indirmesi başlatıldı."
    }

    public func deleteDownload(_ item: DownloadItem) {
        storage.deleteDownload(id: item.id)
        toastMessage = "“\(item.title)” silindi."
    }

    public func togglePvrRecording(channel: ChannelItem) {
        if pvrRecordingState.isRecording {
            stopPvrRecording()
        } else {
            startPvrRecording(channel: channel)
        }
    }

    public func startPvrRecording(channel: ChannelItem) {
        let started = pvrService.startRecording(channel: channel)
        if started {
            toastMessage = "🔴 “\(channel.name)” canlı yayını kaydedilmeye başlandı."
        } else {
            toastMessage = "Zaten aktif bir yayın kaydı bulunuyor."
        }
    }

    public func stopPvrRecording() {
        if pvrService.stopRecording() != nil {
            toastMessage = "✅ Canlı yayın kaydı başarıyla kaydedildi! 'İndirilenler & Kayıtlar' sekmesinden izleyebilirsiniz."
        } else {
            toastMessage = "❌ Canlı yayın kaydı durduruldu veya yayın verisi yetersiz."
        }
    }

    public func cancelPvrRecording() {
        pvrService.cancelRecording()
        toastMessage = "Canlı yayın kaydı iptal edildi."
    }

    // MARK: - Binge Watch (Next Episode)
    public func getNextEpisode() -> ChannelItem? {
        guard let current = currentlyPlayingChannel, current.streamType == "SERIES" else { return nil }
        guard let idx = seriesChannels.firstIndex(where: { $0.id == current.id }), idx + 1 < seriesChannels.count else { return nil }
        let next = seriesChannels[idx + 1]
        return next.groupTitle.caseInsensitiveCompare(current.groupTitle) == .orderedSame ? next : nil
    }

    public func playNextEpisode() {
        if let next = getNextEpisode() {
            playChannel(next)
            toastMessage = "Sonraki bölüme geçildi: \(next.name)"
        }
    }

    // MARK: - Clear Actions
    public func clearAllFavorites() {
        storage.clearAllFavorites()
        toastMessage = "Favoriler temizlendi."
    }

    public func clearWatchHistory() {
        storage.clearWatchHistory()
        toastMessage = "İzleme geçmişi temizlendi."
    }

    public func clearAllData() {
        storage.clearAllData()
        currentlyPlayingChannel = nil
        toastMessage = "Tüm veriler sıfırlandı."
    }

    public func acceptDisclaimer() {
        hasAcceptedDisclaimer = true
    }
}

// Actor helper for TmdbService key
extension TmdbService {
    func setApiKey(_ key: String) {
        self.apiKey = key
    }
}
