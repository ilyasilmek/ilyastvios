import Foundation

public struct PvrRecordingState: Equatable {
    public var isRecording: Bool
    public var channel: ChannelItem?
    public var elapsedSeconds: Int
    public var bytesRecorded: Int64
    public var filePath: String?

    public init(
        isRecording: Bool = false,
        channel: ChannelItem? = nil,
        elapsedSeconds: Int = 0,
        bytesRecorded: Int64 = 0,
        filePath: String? = nil
    ) {
        self.isRecording = isRecording
        self.channel = channel
        self.elapsedSeconds = elapsedSeconds
        self.bytesRecorded = bytesRecorded
        self.filePath = filePath
    }

    public var elapsedSecondsFormatted: String {
        let hrs = elapsedSeconds / 3600
        let mins = (elapsedSeconds % 3600) / 60
        let secs = elapsedSeconds % 60
        if hrs > 0 {
            return String(format: "%02d:%02d:%02d", hrs, mins, secs)
        } else {
            return String(format: "%02d:%02d", mins, secs)
        }
    }

    public var recordedBytesFormatted: String {
        if bytesRecorded <= 0 { return "0 MB" }
        let mb = Double(bytesRecorded) / (1024.0 * 1024.0)
        if mb >= 1024.0 {
            return String(format: "%.2f GB", mb / 1024.0)
        } else {
            return String(format: "%.1f MB", mb)
        }
    }
}
