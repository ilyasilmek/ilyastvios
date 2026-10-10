import SwiftUI

public enum AppColors {
    public static let liveRed = Color(red: 229/255, green: 57/255, blue: 53/255)
    public static let brandAmber = Color(red: 255/255, green: 179/255, blue: 0/255)
    public static let brandBlue = Color(red: 66/255, green: 133/255, blue: 244/255)
    public static let brandPurple = Color(red: 127/255, green: 82/255, blue: 255/255)
    public static let brandGreen = Color(red: 71/255, green: 162/255, blue: 72/255)

    // Dark Cinema Palette
    public static let backgroundDark = Color(red: 15/255, green: 15/255, blue: 18/255)
    public static let surfaceDark = Color(red: 25/255, green: 25/255, blue: 30/255)
    public static let cardDark = Color(red: 35/255, green: 35/255, blue: 42/255)
    public static let borderDark = Color.white.opacity(0.1)
    public static let textPrimary = Color.white
    public static let textSecondary = Color(white: 0.7)
    public static let textMuted = Color(white: 0.45)
}

public enum ViewModeSetting: String, CaseIterable, Codable {
    case grid = "GRID"
    case list = "LIST"

    public var title: String {
        switch self {
        case .grid: return "Izgara Görünümü"
        case .list: return "Liste Görünümü"
        }
    }
}

public enum BufferOption: String, CaseIterable, Codable {
    case lowLatency = "LOW_LATENCY"
    case normal = "NORMAL"
    case maxBuffer = "MAX_BUFFER"

    public var label: String {
        switch self {
        case .lowLatency: return "Düşük Gecikme"
        case .normal: return "Dengeli (Önerilen)"
        case .maxBuffer: return "Yüksek Arabellek"
        }
    }

    public var description: String {
        switch self {
        case .lowLatency: return "Canlı yayınlar için hızlı başlangıç, düşük arabellek"
        case .normal: return "Akıcı yayın için standart arabellek boyutu"
        case .maxBuffer: return "Dalgalı internet bağlantıları için önceden yükleme"
        }
    }
}

public enum ThemeBrandStyle: String, CaseIterable, Codable {
    case sinema = "SINEMA"
    case modern = "MODERN"
    case klasik = "KLASIK"

    public var title: String {
        switch self {
        case .sinema: return "Sinema Kırmızısı"
        case .modern: return "Modern Amber"
        case .klasik: return "Klasik Mavi"
        }
    }

    public var primaryColor: Color {
        switch self {
        case .sinema: return AppColors.liveRed
        case .modern: return AppColors.brandAmber
        case .klasik: return AppColors.brandBlue
        }
    }
}
