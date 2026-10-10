import Foundation
import Combine

public final class PvrService: NSObject, ObservableObject {
    public static let shared = PvrService()

    @Published public private(set) var recordingState = PvrRecordingState()

    private var timer: Timer?
    private var recordingTask: Task<Void, Never>?
    private var outputStream: OutputStream?
    private var targetFileURL: URL?

    private override init() {
        super.init()
    }

    public func startRecording(channel: ChannelItem) -> Bool {
        guard !recordingState.isRecording else { return false }

        let safeName = channel.name.replacingOccurrences(of: #"[\\/:*?"<>|\s]+"#, with: "_", options: .regularExpression).prefix(30)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let fileName = "PVR_\(safeName)_\(timestamp).ts"

        let moviesDir = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask).first ??
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = moviesDir.appendingPathComponent(fileName)

        targetFileURL = fileURL

        recordingState = PvrRecordingState(
            isRecording: true,
            channel: channel,
            elapsedSeconds: 0,
            bytesRecorded: 0,
            filePath: fileURL.path
        )

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, self.recordingState.isRecording else { return }
            self.recordingState.elapsedSeconds += 1
        }

        recordingTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            await self.streamRecordingLoop(streamUrl: channel.streamUrl, targetURL: fileURL)
        }

        return true
    }

    private func streamRecordingLoop(streamUrl: String, targetURL: URL) async {
        guard let url = URL(string: streamUrl) else { return }
        var request = URLRequest(url: url)
        request.setValue("VLC/3.0.18 LibVLC/3.0.18 (iOS 17; Mobile)", forHTTPHeaderField: "User-Agent")
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30.0

        do {
            let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return }

            FileManager.default.createFile(atPath: targetURL.path, contents: nil)
            guard let handle = try? FileHandle(forWritingTo: targetURL) else { return }
            defer { try? handle.close() }

            var buffer = Data()
            buffer.reserveCapacity(64 * 1024)
            var totalBytes: Int64 = 0

            for try await byte in asyncBytes {
                if Task.isCancelled || !recordingState.isRecording { break }
                buffer.append(byte)

                if buffer.count >= 64 * 1024 {
                    try? handle.write(contentsOf: buffer)
                    totalBytes += Int64(buffer.count)
                    buffer.removeAll(keepingCapacity: true)

                    let currentTotal = totalBytes
                    await MainActor.run {
                        self.recordingState.bytesRecorded = currentTotal
                    }
                }
            }

            if !buffer.isEmpty {
                try? handle.write(contentsOf: buffer)
                totalBytes += Int64(buffer.count)
                let currentTotal = totalBytes
                await MainActor.run {
                    self.recordingState.bytesRecorded = currentTotal
                }
            }
        } catch {
            // Stream stopped or cancelled
        }
    }

    public func stopRecording() -> DownloadItem? {
        guard recordingState.isRecording, let channel = recordingState.channel, let fileURL = targetFileURL else {
            return nil
        }

        timer?.invalidate()
        timer = nil
        recordingTask?.cancel()
        recordingTask = nil

        let finalSize = (try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64) ?? 0

        if finalSize < 10240 { // 10 KB'den küçükse başarısız sayıp sil
            try? FileManager.default.removeItem(at: fileURL)
            recordingState = PvrRecordingState(isRecording: false)
            return nil
        }

        let recordingTitle = "🔴 Canlı Kayıt: \(channel.name) (\(recordingState.elapsedSecondsFormatted))"
        let downloadItem = DownloadItem(
            channelId: channel.id,
            title: recordingTitle,
            streamUrl: fileURL.absoluteString,
            localFilePath: fileURL.path,
            posterUrl: channel.logoUrl,
            groupTitle: "PVR Canlı Kayıtlar",
            streamType: "PVR",
            status: .completed,
            progressPercent: 100,
            bytesDownloaded: finalSize,
            totalBytes: finalSize,
            completedAt: Int64(Date().timeIntervalSince1970 * 1000)
        )

        StorageManager.shared.saveDownload(downloadItem)
        recordingState = PvrRecordingState(isRecording: false)
        return downloadItem
    }

    public func cancelRecording() {
        timer?.invalidate()
        timer = nil
        recordingTask?.cancel()
        recordingTask = nil

        if let fileURL = targetFileURL {
            try? FileManager.default.removeItem(at: fileURL)
        }
        recordingState = PvrRecordingState(isRecording: false)
    }
}
