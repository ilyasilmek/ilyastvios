import Foundation

public struct EpgProgramItem: Identifiable, Codable, Hashable {
    public var id: String { "\(startTimeMillis)_\(title)" }
    public var title: String
    public var description: String?
    public var startTimeMillis: Int64
    public var endTimeMillis: Int64
    public var isPast: Bool
    public var isNow: Bool
    public var isFuture: Bool
    public var catchupUrl: String?

    public init(
        title: String,
        description: String? = nil,
        startTimeMillis: Int64,
        endTimeMillis: Int64,
        isPast: Bool = false,
        isNow: Bool = false,
        isFuture: Bool = false,
        catchupUrl: String? = nil
    ) {
        self.title = title
        self.description = description
        self.startTimeMillis = startTimeMillis
        self.endTimeMillis = endTimeMillis
        self.isPast = isPast
        self.isNow = isNow
        self.isFuture = isFuture
        self.catchupUrl = catchupUrl
    }

    public var durationMinutes: Int64 {
        max(1, (endTimeMillis - startTimeMillis) / (60 * 1000))
    }
}
