import Foundation

public struct AccountInfo: Codable, Hashable {
    public var username: String?
    public var serverHost: String?
    public var status: String
    public var expDateTimestamp: Int64? // in milliseconds
    public var maxConnections: String?
    public var activeConnections: String?
    public var isTrial: Bool
    public var rawMessage: String?

    public init(
        username: String? = nil,
        serverHost: String? = nil,
        status: String = "Aktif",
        expDateTimestamp: Int64? = nil,
        maxConnections: String? = "1",
        activeConnections: String? = "1",
        isTrial: Bool = false,
        rawMessage: String? = nil
    ) {
        self.username = username
        self.serverHost = serverHost
        self.status = status
        self.expDateTimestamp = expDateTimestamp
        self.maxConnections = maxConnections
        self.activeConnections = activeConnections
        self.isTrial = isTrial
        self.rawMessage = rawMessage
    }

    public var isExpired: Bool {
        guard let exp = expDateTimestamp, exp > 0 else { return false }
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        return exp <= now
    }

    public var remainingTimeText: String {
        guard let exp = expDateTimestamp else { return "Süresiz / Belirtilmemiş" }
        if exp <= 0 { return "Süresiz" }
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let diff = exp - now
        if diff <= 0 {
            return "⚠️ Abonelik Süresi Doldu"
        }
        let totalSeconds = diff / 1000
        let days = totalSeconds / (24 * 3600)
        let hours = (totalSeconds % (24 * 3600)) / 3600
        let minutes = (totalSeconds % 3600) / 60

        if days > 0 {
            return "\(days) Gün, \(hours) Saat kaldı"
        } else if hours > 0 {
            return "\(hours) Saat, \(minutes) Dakika kaldı"
        } else {
            return "\(minutes) Dakika kaldı"
        }
    }

    public var expirationDateText: String {
        guard let exp = expDateTimestamp, exp > 0 else { return "Süresiz / Belirtilmemiş" }
        let date = Date(timeIntervalSince1970: TimeInterval(exp) / 1000.0)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "dd MMMM yyyy, HH:mm"
        return formatter.string(from: date)
    }
}
