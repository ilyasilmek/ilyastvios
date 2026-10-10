import Foundation

public struct SubtitleLanguage: Identifiable, Hashable {
    public var id: String { code }
    public let name: String
    public let code: String
}

public enum SubtitleService {
    public static let supportedLanguages: [SubtitleLanguage] = [
        SubtitleLanguage(name: "Türkçe", code: "tr"),
        SubtitleLanguage(name: "English", code: "en"),
        SubtitleLanguage(name: "Deutsch", code: "de"),
        SubtitleLanguage(name: "Français", code: "fr"),
        SubtitleLanguage(name: "Español", code: "es"),
        SubtitleLanguage(name: "العربية (Arapça)", code: "ar"),
        SubtitleLanguage(name: "Русский (Rusça)", code: "ru"),
        SubtitleLanguage(name: "Italiano", code: "it")
    ]

    public static func searchSubtitles(title: String, languageCode: String = "tr") async -> [SubtitleItem] {
        let (cleanTitle, _) = TmdbService.cleanMediaTitle(title)
        guard let encoded = cleanTitle.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return [] }
        let apiUrl = "https://subdl.com/api/v1/subtitles?api_key=public&query=\(encoded)&languages=\(languageCode)"
        guard let url = URL(string: apiUrl) else { return [] }

        var request = URLRequest(url: url)
        request.setValue("IlyasTV-IPTV/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15.0

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return [] }
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [] }
            let results = (json["subtitles"] as? [[String: Any]]) ?? (json["results"] as? [[String: Any]]) ?? []

            var list: [SubtitleItem] = []
            for (idx, obj) in results.enumerated() {
                let subName = (obj["release_name"] as? String) ?? (obj["name"] as? String) ?? "\(cleanTitle) (\(languageCode))"
                let urlStr = (obj["url"] as? String) ?? (obj["download_url"] as? String) ?? ""
                let lang = (obj["lang"] as? String) ?? languageCode
                if !urlStr.isEmpty {
                    list.append(
                        SubtitleItem(
                            id: "subdl_\(idx)_\(Int64(Date().timeIntervalSince1970 * 1000))",
                            title: subName,
                            language: lang == "tr" ? "Türkçe" : lang.uppercased(),
                            languageCode: lang,
                            downloadUrl: urlStr,
                            sourceName: "SubDL Multi-Source"
                        )
                    )
                }
            }
            return list
        } catch {
            return []
        }
    }

    public static func downloadSubtitleFile(item: SubtitleItem) async -> URL? {
        guard let url = URL(string: item.downloadUrl) else { return nil }
        var request = URLRequest(url: url)
        request.setValue("IlyasTV-IPTV/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15.0

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, !data.isEmpty else { return nil }

            let fileManager = FileManager.default
            let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("subtitles")
            if !fileManager.fileExists(atPath: cacheDir.path) {
                try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
            }

            let safeName = item.title.replacingOccurrences(of: #"[\\/:*?"<>|\s]+"#, with: "_", options: .regularExpression).prefix(30)
            let fileURL = cacheDir.appendingPathComponent("\(safeName)_\(item.languageCode).srt")

            try data.write(to: fileURL)
            return fileURL
        } catch {
            return nil
        }
    }
}
