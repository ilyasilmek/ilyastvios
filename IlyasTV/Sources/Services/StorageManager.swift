import Foundation
import Combine

public final class StorageManager: ObservableObject {
    public static let shared = StorageManager()

    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "com.ilyastv.storagemanager", qos: .userInitiated)

    private var appSupportDir: URL {
        let urls = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let dir = urls[0].appendingPathComponent("IlyasTV", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private var channelsFile: URL { appSupportDir.appendingPathComponent("channels.json") }
    private var playlistsFile: URL { appSupportDir.appendingPathComponent("playlists.json") }
    private var downloadsFile: URL { appSupportDir.appendingPathComponent("downloads.json") }
    private var searchHistoryFile: URL { appSupportDir.appendingPathComponent("search_history.json") }

    @Published public private(set) var channels: [ChannelItem] = []
    @Published public private(set) var playlists: [PlaylistItem] = []
    @Published public private(set) var downloads: [DownloadItem] = []
    @Published public private(set) var searchHistory: [String] = []

    private init() {
        loadData()
    }

    public func loadData() {
        queue.sync {
            let loadedChannels: [ChannelItem] = readJSON(from: channelsFile) ?? []
            let loadedPlaylists: [PlaylistItem] = readJSON(from: playlistsFile) ?? []
            let loadedDownloads: [DownloadItem] = readJSON(from: downloadsFile) ?? []
            let loadedHistory: [String] = readJSON(from: searchHistoryFile) ?? []

            DispatchQueue.main.async {
                self.channels = loadedChannels
                self.playlists = loadedPlaylists
                self.downloads = loadedDownloads
                self.searchHistory = loadedHistory
            }
        }
    }

    // MARK: - Playlists
    public func addPlaylist(_ playlist: PlaylistItem, newChannels: [ChannelItem]) {
        queue.async {
            var plList = self.playlists
            plList.removeAll { $0.id == playlist.id }
            plList.insert(playlist, at: 0)

            var chList = self.channels
            // Playlist ID'ye göre eski kanalları temizle ve yenilerini ekle
            chList.removeAll { $0.playlistId == playlist.id }
            chList.append(contentsOf: newChannels)

            self.writeJSON(plList, to: self.playlistsFile)
            self.writeJSON(chList, to: self.channelsFile)

            DispatchQueue.main.async {
                self.playlists = plList
                self.channels = chList
            }
        }
    }

    public func updatePlaylist(_ playlist: PlaylistItem) {
        queue.async {
            var plList = self.playlists
            if let idx = plList.firstIndex(where: { $0.id == playlist.id }) {
                plList[idx] = playlist
            }
            self.writeJSON(plList, to: self.playlistsFile)
            DispatchQueue.main.async {
                self.playlists = plList
            }
        }
    }

    public func deletePlaylist(id: Int64) {
        queue.async {
            var plList = self.playlists
            plList.removeAll { $0.id == id }

            var chList = self.channels
            chList.removeAll { $0.playlistId == id }

            self.writeJSON(plList, to: self.playlistsFile)
            self.writeJSON(chList, to: self.channelsFile)

            DispatchQueue.main.async {
                self.playlists = plList
                self.channels = chList
            }
        }
    }

    // MARK: - Channels & Favorites & History
    public func toggleFavorite(channelId: Int64) {
        queue.async {
            var chList = self.channels
            if let idx = chList.firstIndex(where: { $0.id == channelId }) {
                chList[idx].isFavorite.toggle()
                self.writeJSON(chList, to: self.channelsFile)
                DispatchQueue.main.async {
                    self.channels = chList
                }
            }
        }
    }

    public func recordChannelPlayed(channelId: Int64) {
        queue.async {
            var chList = self.channels
            if let idx = chList.firstIndex(where: { $0.id == channelId }) {
                chList[idx].lastPlayedTimestamp = Int64(Date().timeIntervalSince1970 * 1000)
                self.writeJSON(chList, to: self.channelsFile)
                DispatchQueue.main.async {
                    self.channels = chList
                }
            }
        }
    }

    public func updatePlaybackProgress(channelId: Int64, positionMs: Int64, durationMs: Int64) {
        queue.async {
            var chList = self.channels
            if let idx = chList.firstIndex(where: { $0.id == channelId }) {
                chList[idx].playbackPositionMs = positionMs
                chList[idx].durationMs = durationMs
                self.writeJSON(chList, to: self.channelsFile)
                DispatchQueue.main.async {
                    self.channels = chList
                }
            }
        }
    }

    public func resetPlaybackProgress(channelId: Int64) {
        queue.async {
            var chList = self.channels
            if let idx = chList.firstIndex(where: { $0.id == channelId }) {
                chList[idx].playbackPositionMs = 0
                self.writeJSON(chList, to: self.channelsFile)
                DispatchQueue.main.async {
                    self.channels = chList
                }
            }
        }
    }

    public func removeFromWatchHistory(channelId: Int64) {
        queue.async {
            var chList = self.channels
            if let idx = chList.firstIndex(where: { $0.id == channelId }) {
                chList[idx].lastPlayedTimestamp = 0
                chList[idx].playbackPositionMs = 0
                self.writeJSON(chList, to: self.channelsFile)
                DispatchQueue.main.async {
                    self.channels = chList
                }
            }
        }
    }

    public func moveWatchHistoryToTop(channelId: Int64) {
        queue.async {
            var chList = self.channels
            if let idx = chList.firstIndex(where: { $0.id == channelId }) {
                chList[idx].lastPlayedTimestamp = Int64(Date().timeIntervalSince1970 * 1000) + 1000
                self.writeJSON(chList, to: self.channelsFile)
                DispatchQueue.main.async {
                    self.channels = chList
                }
            }
        }
    }

    public func clearAllFavorites() {
        queue.async {
            var chList = self.channels
            for i in 0..<chList.count {
                chList[i].isFavorite = false
            }
            self.writeJSON(chList, to: self.channelsFile)
            DispatchQueue.main.async {
                self.channels = chList
            }
        }
    }

    public func clearWatchHistory() {
        queue.async {
            var chList = self.channels
            for i in 0..<chList.count {
                chList[i].lastPlayedTimestamp = 0
                chList[i].playbackPositionMs = 0
            }
            self.writeJSON(chList, to: self.channelsFile)
            DispatchQueue.main.async {
                self.channels = chList
            }
        }
    }

    // MARK: - Downloads
    public func saveDownload(_ item: DownloadItem) {
        queue.async {
            var dList = self.downloads
            if let idx = dList.firstIndex(where: { $0.id == item.id }) {
                dList[idx] = item
            } else {
                dList.insert(item, at: 0)
            }
            self.writeJSON(dList, to: self.downloadsFile)
            DispatchQueue.main.async {
                self.downloads = dList
            }
        }
    }

    public func deleteDownload(id: Int64) {
        queue.async {
            var dList = self.downloads
            if let item = dList.first(where: { $0.id == id }) {
                if let path = item.localFilePath, FileManager.default.fileExists(atPath: path) {
                    try? FileManager.default.removeItem(atPath: path)
                }
            }
            dList.removeAll { $0.id == id }
            self.writeJSON(dList, to: self.downloadsFile)
            DispatchQueue.main.async {
                self.downloads = dList
            }
        }
    }

    // MARK: - Search History
    public func addSearchQuery(_ query: String) {
        let clean = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard clean.count >= 2 else { return }
        queue.async {
            var history = self.searchHistory
            history.removeAll { $0.lowercased() == clean.lowercased() }
            history.insert(clean, at: 0)
            if history.count > 15 { history = Array(history.prefix(15)) }
            self.writeJSON(history, to: self.searchHistoryFile)
            DispatchQueue.main.async {
                self.searchHistory = history
            }
        }
    }

    public func removeSearchQuery(_ query: String) {
        queue.async {
            var history = self.searchHistory
            history.removeAll { $0 == query }
            self.writeJSON(history, to: self.searchHistoryFile)
            DispatchQueue.main.async {
                self.searchHistory = history
            }
        }
    }

    public func clearSearchHistory() {
        queue.async {
            self.writeJSON([String](), to: self.searchHistoryFile)
            DispatchQueue.main.async {
                self.searchHistory = []
            }
        }
    }

    public func clearAllData() {
        queue.async {
            for d in self.downloads {
                if let p = d.localFilePath, FileManager.default.fileExists(atPath: p) {
                    try? FileManager.default.removeItem(atPath: p)
                }
            }
            self.writeJSON([ChannelItem](), to: self.channelsFile)
            self.writeJSON([PlaylistItem](), to: self.playlistsFile)
            self.writeJSON([DownloadItem](), to: self.downloadsFile)
            self.writeJSON([String](), to: self.searchHistoryFile)

            DispatchQueue.main.async {
                self.channels = []
                self.playlists = []
                self.downloads = []
                self.searchHistory = []
            }
        }
    }

    // Helper JSON Read/Write
    private func readJSON<T: Decodable>(from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func writeJSON<T: Encodable>(_ object: T, to url: URL) {
        guard let data = try? JSONEncoder().encode(object) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
