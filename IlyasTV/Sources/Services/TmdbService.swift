import Foundation

public actor TmdbService {
    public static let shared = TmdbService()

    private var cache: [String: TmdbMetadata] = [:]
    private let baseURL = "https://api.themoviedb.org/3"
    private let imageBaseURL = "https://image.tmdb.org/t/p/w500"
    private let backdropBaseURL = "https://image.tmdb.org/t/p/w780"

    // Optional TMDb key or user configured
    public var apiKey: String = ""

    public static func cleanMediaTitle(_ rawTitle: String) -> (cleanTitle: String, year: String?) {
        var clean = rawTitle
        let patterns = [
            #"(?i)^(TR|EN|FR|DE|AZ|RU|AR)\s*[:|\-]\s*"#,
            #"(?i)\[(TR|4K|1080P|720P|FHD|UHD|HDR|HEVC|DUBLAJ|ALTYAZILI)\]"#,
            #"(?i)\b(4K|1080p|720p|FHD|UHD|HDR|HEVC|BluRay|WEB-DL|DUBLAJ|ALTYAZILI)\b"#,
            #"(?i)S[0-9]{1,2}\s*E[0-9]{1,2}.*"#,
            #"(?i)[0-9]{1,2}\.\s*Sezon.*"#
        ]

        for p in patterns {
            clean = clean.replacingOccurrences(of: p, with: "", options: .regularExpression)
        }
        clean = clean.trimmingCharacters(in: .whitespacesAndNewlines)

        var year: String? = nil
        if let yearMatch = try? NSRegularExpression(pattern: #"\b(19\d\d|20\d\d)\b"#).firstMatch(in: clean, range: NSRange(location: 0, length: clean.utf16.count)) {
            if let range = Range(yearMatch.range, in: clean) {
                year = String(clean[range])
                clean = clean.replacingOccurrences(of: "(\(year!))", with: "").replacingOccurrences(of: year!, with: "")
            }
        }

        clean = clean.replacingOccurrences(of: #"[\-_]+"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return (clean.isEmpty ? rawTitle : clean, year)
    }

    public func getMetadata(title: String, isSeries: Bool = false) async -> TmdbMetadata? {
        if apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return nil
        }

        let (cleanedTitle, year) = Self.cleanMediaTitle(title)
        let cacheKey = "\(isSeries ? "tv" : "movie")_\(cleanedTitle)"
        if let cached = cache[cacheKey] { return cached }

        guard let encodedQuery = cleanedTitle.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        let type = isSeries ? "tv" : "movie"
        var urlString = "\(baseURL)/search/\(type)?api_key=\(apiKey)&language=tr-TR&query=\(encodedQuery)"
        if let y = year {
            urlString += isSeries ? "&first_air_date_year=\(y)" : "&year=\(y)"
        }

        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return nil }
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let results = json["results"] as? [[String: Any]] else {
                return nil
            }

            if results.isEmpty {
                // English fallback
                let enUrlStr = "\(baseURL)/search/\(type)?api_key=\(apiKey)&language=en-US&query=\(encodedQuery)"
                guard let enUrl = URL(string: enUrlStr),
                      let (enData, enResp) = try? await URLSession.shared.data(from: enUrl),
                      (enResp as? HTTPURLResponse)?.statusCode == 200,
                      let enJson = (try? JSONSerialization.jsonObject(with: enData)) as? [String: Any],
                      let enResults = enJson["results"] as? [[String: Any]], !enResults.isEmpty else {
                    return nil
                }
                let meta = parseTmdbItem(enResults[0], isSeries: isSeries)
                cache[cacheKey] = meta
                return meta
            }

            let meta = parseTmdbItem(results[0], isSeries: isSeries)
            cache[cacheKey] = meta
            return meta
        } catch {
            return nil
        }
    }

    private func parseTmdbItem(_ item: [String: Any], isSeries: Bool) -> TmdbMetadata {
        let tmdbId = item["id"] as? Int64
        let title = (isSeries ? (item["name"] as? String) : (item["title"] as? String)) ?? ""
        let originalTitle = (isSeries ? (item["original_name"] as? String) : (item["original_title"] as? String))
        let overview = (item["overview"] as? String) ?? ""
        let posterPath = (item["poster_path"] as? String) ?? ""
        let backdropPath = (item["backdrop_path"] as? String) ?? ""
        let rating = (item["vote_average"] as? Double) ?? 0.0
        let voteCount = (item["vote_count"] as? Int) ?? 0
        let dateStr = (isSeries ? (item["first_air_date"] as? String) : (item["release_date"] as? String)) ?? ""
        let releaseYear = dateStr.count >= 4 ? String(dateStr.prefix(4)) : nil

        var genres: [String] = []
        if let genreIds = item["genre_ids"] as? [Int] {
            genres = genreIds.compactMap { getGenreName(id: $0) }
        }

        let encodedName = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let trailerUrl = "https://www.youtube.com/results?search_query=\(encodedName)+fragman+trailer"

        return TmdbMetadata(
            title: title.isEmpty ? (originalTitle ?? "") : title,
            originalTitle: originalTitle,
            overview: overview.isEmpty ? "Bu yapım için özet açıklaması hazırlanıyor." : overview,
            posterUrl: !posterPath.isEmpty && posterPath != "null" ? "\(imageBaseURL)\(posterPath)" : nil,
            backdropUrl: !backdropPath.isEmpty && backdropPath != "null" ? "\(backdropBaseURL)\(backdropPath)" : nil,
            rating: (rating * 10).rounded() / 10,
            voteCount: voteCount,
            releaseYear: releaseYear,
            genres: Array(genres.prefix(4)),
            tmdbId: tmdbId,
            trailerUrl: trailerUrl
        )
    }

    private func getGenreName(id: Int) -> String? {
        switch id {
        case 28: return "Aksiyon"
        case 12: return "Macera"
        case 16: return "Animasyon"
        case 35: return "Komedi"
        case 80: return "Suç"
        case 99: return "Belgesel"
        case 18: return "Dram"
        case 10751: return "Aile"
        case 14: return "Fantastik"
        case 36: return "Tarih"
        case 27: return "Korku"
        case 10402: return "Müzik"
        case 9648: return "Gizem"
        case 10749: return "Romantik"
        case 878: return "Bilim Kurgu"
        case 10770: return "TV Filmi"
        case 53: return "Gerilim"
        case 10752: return "Savaş"
        case 37: return "Vahşi Batı"
        case 10759: return "Aksiyon & Macera"
        case 10765: return "Bilim Kurgu & Fantastik"
        default: return nil
        }
    }
}
