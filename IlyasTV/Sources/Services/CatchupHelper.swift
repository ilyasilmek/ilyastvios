import Foundation

public enum CatchupHelper {
    public static func buildCatchupUrl(
        channel: ChannelItem,
        programStartTimeMs: Int64,
        durationMinutes: Int64
    ) -> String {
        let originalUrl = channel.streamUrl
        let startSec = programStartTimeMs / 1000
        let durationMin = max(5, durationMinutes)

        // Xtream format: http://host/live/user/pass/id.ts -> http://host/timeshift/user/pass/duration/start/id.ts
        let pattern = #"^(https?://[^/]+)/(?:live/)?([^/]+)/([^/]+)/(\d+)(?:\.ts|\.m3u8)?"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: originalUrl, range: NSRange(location: 0, length: originalUrl.utf16.count)) {
            if match.numberOfRanges >= 5,
               let hostRange = Range(match.range(at: 1), in: originalUrl),
               let userRange = Range(match.range(at: 2), in: originalUrl),
               let passRange = Range(match.range(at: 3), in: originalUrl),
               let streamIdRange = Range(match.range(at: 4), in: originalUrl) {
                let host = String(originalUrl[hostRange])
                let user = String(originalUrl[userRange])
                let pass = String(originalUrl[passRange])
                let streamId = String(originalUrl[streamIdRange])

                let date = Date(timeIntervalSince1970: TimeInterval(programStartTimeMs) / 1000.0)
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US")
                formatter.dateFormat = "yyyy-MM-dd:HH-mm"
                let startTimeStr = formatter.string(from: date)

                return "\(host)/timeshift/\(user)/\(pass)/\(durationMin)/\(startTimeStr)/\(streamId).ts"
            }
        }

        let separator = originalUrl.contains("?") ? "&" : "?"
        let nowSec = Int64(Date().timeIntervalSince1970)
        return "\(originalUrl)\(separator)utc=\(startSec)&lutc=\(nowSec)"
    }

    public static func generateScheduleForChannel(channel: ChannelItem) -> [EpgProgramItem] {
        return []
    }
}
