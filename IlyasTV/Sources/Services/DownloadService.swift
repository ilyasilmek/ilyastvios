import Foundation
import Combine

public final class DownloadService: NSObject, ObservableObject, URLSessionDownloadDelegate {
    public static let shared = DownloadService()

    private var session: URLSession!
    private var tasks: [Int: Int64] = [:] // TaskIdentifier: DownloadId
    private var activeDownloads: [Int64: URLSessionDownloadTask] = [:]

    private override init() {
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier: "com.ilyastv.downloads")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
    }

    public func startDownload(channel: ChannelItem) -> Int64 {
        let extensionStr: String
        let lower = channel.streamUrl.lowercased()
        if lower.contains(".mp4") { extensionStr = "mp4" }
        else if lower.contains(".mkv") { extensionStr = "mkv" }
        else if lower.contains(".ts") || lower.contains(".m3u8") { extensionStr = "ts" }
        else { extensionStr = "mp4" }

        let safeName = channel.name.replacingOccurrences(of: #"[\\/:*?"<>|\s]+"#, with: "_", options: .regularExpression).prefix(30)
        let fileName = "IlyasTV_\(safeName)_\(channel.id).\(extensionStr)"

        let moviesDir = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask).first ??
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let targetFileURL = moviesDir.appendingPathComponent(fileName)

        let downloadItem = DownloadItem(
            channelId: channel.id,
            title: channel.name,
            streamUrl: channel.streamUrl,
            localFilePath: targetFileURL.path,
            posterUrl: channel.posterUrl ?? channel.logoUrl,
            groupTitle: channel.groupTitle,
            streamType: channel.streamType,
            status: .downloading,
            progressPercent: 0,
            bytesDownloaded: 0,
            totalBytes: 0
        )

        StorageManager.shared.saveDownload(downloadItem)

        if let url = URL(string: channel.streamUrl) {
            var request = URLRequest(url: url)
            request.setValue("VLC/3.0.18 LibVLC/3.0.18 (iOS 17; Mobile)", forHTTPHeaderField: "User-Agent")
            let task = session.downloadTask(with: request)
            tasks[task.taskIdentifier] = downloadItem.id
            activeDownloads[downloadItem.id] = task
            task.resume()
        }

        return downloadItem.id
    }

    public func cancelDownload(id: Int64) {
        if let task = activeDownloads[id] {
            task.cancel()
            activeDownloads.removeValue(forKey: id)
        }
        StorageManager.shared.deleteDownload(id: id)
    }

    // MARK: - URLSessionDownloadDelegate
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let downloadId = tasks[downloadTask.taskIdentifier] else { return }
        tasks.removeValue(forKey: downloadTask.taskIdentifier)
        activeDownloads.removeValue(forKey: downloadId)

        if var item = StorageManager.shared.downloads.first(where: { $0.id == downloadId }),
           let targetPath = item.localFilePath {
            let targetURL = URL(fileURLWithPath: targetPath)
            try? FileManager.default.removeItem(at: targetURL)
            try? FileManager.default.moveItem(at: location, to: targetURL)

            let fileSize = (try? FileManager.default.attributesOfItem(atPath: targetPath)[.size] as? Int64) ?? 0
            item.status = .completed
            item.progressPercent = 100
            item.bytesDownloaded = fileSize
            item.totalBytes = fileSize
            item.completedAt = Int64(Date().timeIntervalSince1970 * 1000)

            StorageManager.shared.saveDownload(item)
        }
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let downloadId = tasks[downloadTask.taskIdentifier] else { return }
        if var item = StorageManager.shared.downloads.first(where: { $0.id == downloadId }) {
            let percent = totalBytesExpectedToWrite > 0 ? Int(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) * 100.0) : 0
            item.bytesDownloaded = totalBytesWritten
            item.totalBytes = max(totalBytesWritten, totalBytesExpectedToWrite)
            item.progressPercent = min(100, max(0, percent))
            StorageManager.shared.saveDownload(item)
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let downloadId = tasks[task.taskIdentifier], let error = error else { return }
        tasks.removeValue(forKey: task.taskIdentifier)
        activeDownloads.removeValue(forKey: downloadId)

        if var item = StorageManager.shared.downloads.first(where: { $0.id == downloadId }) {
            item.status = .failed
            item.errorMessage = error.localizedDescription
            StorageManager.shared.saveDownload(item)
        }
    }
}
