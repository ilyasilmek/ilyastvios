import Foundation

public struct ParseResult {
    public let channels: [ChannelItem]
    public let accountInfo: AccountInfo
}

public enum M3uParser {

    private static let tvgIdRegex = try! NSRegularExpression(pattern: #"tvg-id="([^"]*)""#, options: .caseInsensitive)
    private static let tvgNameRegex = try! NSRegularExpression(pattern: #"tvg-name="([^"]*)""#, options: .caseInsensitive)
    private static let tvgLogoRegex = try! NSRegularExpression(pattern: #"tvg-logo="([^"]*)""#, options: .caseInsensitive)
    private static let groupTitleRegex = try! NSRegularExpression(pattern: #"group-title="([^"]*)""#, options: .caseInsensitive)
    private static let expDateRegex = try! NSRegularExpression(pattern: #"(?:exp_date|exp-date|x-exp|expiry)=["']?([0-9]+)["']?"#, options: .caseInsensitive)

    public static func parse(from urlString: String, playlistId: Int64 = 0) async throws -> ParseResult {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.setValue("StreamFlow-IPTV/1.0 (iOS; AVPlayer)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 30.0

        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw NSError(domain: "M3uParser", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Oynatma listesi indirilemedi: HTTP \(httpResponse.statusCode)"])
        }

        guard let content = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
            throw NSError(domain: "M3uParser", code: -1, userInfo: [NSLocalizedDescriptionKey: "Liste karakter kodlaması okunamadı."])
        }

        return await parse(content: content, playlistId: playlistId, sourceUrl: urlString)
    }

    public static func parse(content: String, playlistId: Int64 = 0, sourceUrl: String? = nil) async -> ParseResult {
        var channels: [ChannelItem] = []
        var currentExtInf: String? = nil
        var headerExpTimestamp: Int64? = nil

        var detectedHost: String? = nil
        var detectedUser: String? = nil
        var detectedPass: String? = nil

        if let source = sourceUrl, !source.isEmpty {
            if let creds = extractCredentials(from: source) {
                detectedHost = creds.host
                detectedUser = creds.username
                detectedPass = creds.password
            }
        }

        let lines = content.components(separatedBy: .newlines)

        for rawLine in lines {
            let trimmed = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }

            if trimmed.lowercased().hasPrefix("#extm3u") {
                if let exp = matchFirst(in: trimmed, regex: expDateRegex) {
                    if let rawNum = Int64(exp) {
                        headerExpTimestamp = rawNum < 100000000000 ? rawNum * 1000 : rawNum
                    }
                }
            } else if trimmed.lowercased().hasPrefix("#extinf:") {
                currentExtInf = trimmed
                if headerExpTimestamp == nil, let exp = matchFirst(in: trimmed, regex: expDateRegex) {
                    if let rawNum = Int64(exp) {
                        headerExpTimestamp = rawNum < 100000000000 ? rawNum * 1000 : rawNum
                    }
                }
            } else if !trimmed.hasPrefix("#") {
                let streamUrl = trimmed
                if detectedUser == nil || detectedPass == nil || detectedHost == nil {
                    if let creds = extractCredentials(from: streamUrl) {
                        detectedHost = creds.host
                        detectedUser = creds.username
                        detectedPass = creds.password
                    }
                }

                if let extInf = currentExtInf {
                    let channel = parseExtInfLine(extInf: extInf, streamUrl: streamUrl, playlistId: playlistId)
                    channels.append(channel)
                    currentExtInf = nil
                } else if streamUrl.lowercased().hasPrefix("http://") || streamUrl.lowercased().hasPrefix("https://") || streamUrl.lowercased().hasPrefix("rtmp://") {
                    let lastPart = streamUrl.components(separatedBy: "/").last ?? "Kanal \(channels.count + 1)"
                    let name = lastPart.components(separatedBy: ".").first ?? "Kanal \(channels.count + 1)"
                    let streamType = determineStreamType(groupTitle: nil, streamUrl: streamUrl, displayName: name)
                    channels.append(
                        ChannelItem(
                            playlistId: playlistId,
                            name: name.isEmpty ? "Kanal \(channels.count + 1)" : name,
                            streamUrl: streamUrl,
                            groupTitle: "Genel",
                            streamType: streamType,
                            quality: "1080p"
                        )
                    )
                }
            }
        }

        var fetchedAccountInfo: AccountInfo? = nil
        if let host = detectedHost, let user = detectedUser, let pass = detectedPass {
            fetchedAccountInfo = await fetchXtreamAccountInfo(host: host, user: user, pass: pass)
        }

        let fallbackHost = sourceUrl.flatMap { URL(string: $0)?.host }
        let finalAccountInfo = fetchedAccountInfo ?? AccountInfo(
            username: detectedUser ?? (sourceUrl != nil ? "M3U Linki" : "Yerel Dosya"),
            serverHost: detectedHost ?? fallbackHost,
            status: "Aktif",
            expDateTimestamp: headerExpTimestamp,
            maxConnections: "1",
            activeConnections: "1",
            isTrial: false
        )

        return ParseResult(channels: channels, accountInfo: finalAccountInfo)
    }

    private struct XtreamCredentials {
        let host: String
        let username: String
        let password: String
    }

    private static func extractCredentials(from urlStr: String) -> XtreamCredentials? {
        guard let url = URL(string: urlStr) else { return nil }
        var host = "\(url.scheme ?? "http")://\(url.host ?? "")"
        if let port = url.port, port != 80, port != 443 {
            host += ":\(port)"
        }

        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            let userParam = components.queryItems?.first(where: { $0.name == "username" || $0.name == "user" })?.value
            let passParam = components.queryItems?.first(where: { $0.name == "password" || $0.name == "pass" })?.value
            if let u = userParam, let p = passParam, !u.isEmpty, !p.isEmpty {
                return XtreamCredentials(host: host, username: u, password: p)
            }
        }

        let segments = url.pathComponents.filter { $0 != "/" }
        if segments.count >= 3 {
            let seg0 = segments[0].lowercased()
            if seg0 == "live" || seg0 == "movie" || seg0 == "series" || seg0 == "get.php" {
                let user = segments[1]
                let pass = segments[2].components(separatedBy: ".").first ?? segments[2]
                if !user.isEmpty && !pass.isEmpty {
                    return XtreamCredentials(host: host, username: user, password: pass)
                }
            }
        }
        return nil
    }

    public static func fetchXtreamAccountInfo(host: String, user: String, pass: String) async -> AccountInfo? {
        guard let apiUrl = URL(string: "\(host)/player_api.php?username=\(user)&password=\(pass)") else { return nil }
        var request = URLRequest(url: apiUrl)
        request.setValue("StreamFlow-IPTV/1.0 (iOS; AVPlayer)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15.0

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return nil }
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let userInfo = json["user_info"] as? [String: Any] else {
                return nil
            }

            let username = (userInfo["username"] as? String) ?? user
            let auth = (userInfo["auth"] as? Int) ?? 1
            let rawStatus = (userInfo["status"] as? String)?.lowercased() ?? "active"
            let status: String
            switch rawStatus {
            case "active": status = "Aktif"
            case "expired": status = "Süresi Doldu"
            case "disabled": status = "Devre Dışı"
            case "banned": status = "Engellendi"
            default: status = "Aktif"
            }

            var expTimestamp: Int64? = nil
            if let expStr = userInfo["exp_date"] as? String, let expNum = Int64(expStr), expNum > 0 {
                expTimestamp = expNum < 100000000000 ? expNum * 1000 : expNum
            } else if let expNum = userInfo["exp_date"] as? Int64, expNum > 0 {
                expTimestamp = expNum < 100000000000 ? expNum * 1000 : expNum
            }

            let isTrial = (userInfo["is_trial"] as? String) == "1" || (userInfo["is_trial"] as? Int) == 1
            let activeCons = (userInfo["active_cons"] as? String) ?? "\(userInfo["active_cons"] as? Int ?? 1)"
            let maxCons = (userInfo["max_connections"] as? String) ?? "\(userInfo["max_connections"] as? Int ?? 1)"

            var finalHost = host
            if let serverInfo = json["server_info"] as? [String: Any] {
                let url = (serverInfo["url"] as? String) ?? ""
                let port = (serverInfo["port"] as? String) ?? ""
                if !url.isEmpty {
                    finalHost = !port.isEmpty ? "\(url):\(port)" : url
                }
            }

            return AccountInfo(
                username: username,
                serverHost: finalHost,
                status: auth == 0 ? "Yetkisiz / Hatalı Şifre" : status,
                expDateTimestamp: expTimestamp,
                maxConnections: maxCons,
                activeConnections: activeCons,
                isTrial: isTrial
            )
        } catch {
            return nil
        }
    }

    private static func parseExtInfLine(extInf: String, streamUrl: String, playlistId: Int64) -> ChannelItem {
        let tvgId = matchFirst(in: extInf, regex: tvgIdRegex)
        let tvgName = matchFirst(in: extInf, regex: tvgNameRegex)
        let tvgLogo = matchFirst(in: extInf, regex: tvgLogoRegex)
        let groupTitle = matchFirst(in: extInf, regex: groupTitleRegex)

        let displayName: String
        if let commaIndex = extInf.lastIndex(of: ",") {
            let nextIndex = extInf.index(after: commaIndex)
            displayName = String(extInf[nextIndex...]).trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            displayName = tvgName ?? tvgId ?? "Kanal"
        }

        let category = cleanCategory(raw: groupTitle, displayName: displayName)
        let streamType = determineStreamType(groupTitle: groupTitle, streamUrl: streamUrl, displayName: displayName)

        let upperName = displayName.uppercased()
        let quality: String
        if upperName.contains("4K") || upperName.contains("UHD") {
            quality = "4K"
        } else if upperName.contains("HDR") {
            quality = "HDR"
        } else if upperName.contains("FHD") || upperName.contains("1080") {
            quality = "1080p"
        } else if upperName.contains("HD") || upperName.contains("720") {
            quality = "720p"
        } else {
            quality = "1080p"
        }

        return ChannelItem(
            playlistId: playlistId,
            name: displayName.isEmpty ? (tvgName ?? "Kanal") : displayName,
            streamUrl: streamUrl,
            logoUrl: (tvgLogo?.isEmpty ?? true) ? nil : tvgLogo,
            groupTitle: category,
            streamType: streamType,
            tvgId: tvgId,
            tvgName: tvgName,
            currentProgram: nil,
            programTime: streamType == "LIVE" ? "Canlı Yayın" : "İsteğe Bağlı (VOD)",
            quality: quality
        )
    }

    public static func determineStreamType(groupTitle: String?, streamUrl: String, displayName: String) -> String {
        let lowerUrl = streamUrl.lowercased()
        let lowerGroup = groupTitle?.lowercased() ?? ""
        let lowerName = displayName.lowercased()

        let isSeriesByUrl = lowerUrl.contains("/series/") || lowerUrl.contains("/show/") || lowerUrl.contains("/tvshow/") || lowerUrl.contains("/tvseries/") || lowerUrl.contains("/episodes/")

        let seriesKeywords = ["dizi", "series", "tv show", "tv-show", "sezon", "season", "episode", "bölüm", "bolum", "netflix", "exxen", "blutv", "disney", "gain", "tabii", "prime video", "amazon", "hbo", "apple tv", "anime", "yerli dizi", "yabancı dizi", "yabanci dizi"]
        let isSeriesByGroup = seriesKeywords.contains { lowerGroup.contains($0) }

        let isSeriesByName = lowerName.contains(" s0") || lowerName.contains(" e0") || lowerName.contains(" s1") || lowerName.contains(" e1") || lowerName.contains(" s2") || lowerName.contains(" e2") || lowerName.contains("sezon") || lowerName.contains("season") || lowerName.contains("bölüm") || lowerName.contains("bolum") || lowerName.contains("episode") ||
            (try? NSRegularExpression(pattern: #"(?i)\b(s\d{1,2}|e\d{1,3})\b"#).firstMatch(in: lowerName, range: NSRange(location: 0, length: lowerName.utf16.count))) != nil ||
            (try? NSRegularExpression(pattern: #"(?i)\b(\d{1,2}\.?\s*sezon)\b"#).firstMatch(in: lowerName, range: NSRange(location: 0, length: lowerName.utf16.count))) != nil ||
            (try? NSRegularExpression(pattern: #"(?i)\b(\d{1,3}\.?\s*bölüm|\d{1,3}\.?\s*bolum)\b"#).firstMatch(in: lowerName, range: NSRange(location: 0, length: lowerName.utf16.count))) != nil

        if isSeriesByUrl || isSeriesByGroup || isSeriesByName {
            return "SERIES"
        }

        let isMovieByUrl = lowerUrl.contains("/movie/")
        let movieKeywords = ["vod", "film", "movie", "sinema", "cinema", "4k film", "yerli film", "yabancı film", "yabanci film", "vizyon"]
        let isMovieByGroup = movieKeywords.contains { lowerGroup.contains($0) }

        let isMovieByName = lowerName.hasPrefix("film:") || lowerName.hasPrefix("vod:")
        let isMovieByExtension = (lowerUrl.hasSuffix(".mp4") || lowerUrl.hasSuffix(".mkv") || lowerUrl.hasSuffix(".avi")) && !lowerGroup.contains("live") && !lowerGroup.contains("canlı") && !lowerGroup.contains("canli")

        if isMovieByUrl || isMovieByGroup || isMovieByName || isMovieByExtension {
            return "MOVIE"
        }

        return "LIVE"
    }

    private static func cleanCategory(raw: String?, displayName: String) -> String {
        guard let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            let lower = displayName.lowercased()
            if lower.contains("sport") || lower.contains("spor") || lower.contains("futbol") || lower.contains("bein") { return "Spor" }
            if lower.contains("news") || lower.contains("haber") || lower.contains("cnn") || lower.contains("trthaber") { return "Haber" }
            if lower.contains("movie") || lower.contains("film") || lower.contains("sinema") || lower.contains("cinema") { return "Sinema & Film" }
            if lower.contains("dizi") || lower.contains("series") { return "Diziler" }
            if lower.contains("music") || lower.contains("müzik") || lower.contains("kral") || lower.contains("power") { return "Müzik" }
            if lower.contains("doc") || lower.contains("belgesel") || lower.contains("nat geo") || lower.contains("discovery") { return "Belgesel" }
            if lower.contains("kid") || lower.contains("çocuk") || lower.contains("cartoon") || lower.contains("disney") { return "Çocuk" }
            if lower.contains("ulusal") || lower.contains("trt") || lower.contains("atv") || lower.contains("kanal d") || lower.contains("star") || lower.contains("show") || lower.contains("tv8") { return "Ulusal Kanallar" }
            return "Genel"
        }

        let lower = trimmed.lowercased()
        if lower.contains("sport") || lower.contains("spor") { return "Spor" }
        if lower.contains("news") || lower.contains("haber") { return "Haber" }
        if lower.contains("movie") || lower.contains("film") || lower.contains("sinema") || lower.contains("cinema") { return "Sinema & Film" }
        if lower.contains("dizi") || lower.contains("series") { return "Diziler" }
        if lower.contains("music") || lower.contains("müzik") { return "Müzik" }
        if lower.contains("doc") || lower.contains("belgesel") || lower.contains("nat geo") || lower.contains("discovery") { return "Belgesel" }
        if lower.contains("kid") || lower.contains("çocuk") || lower.contains("cartoon") || lower.contains("disney") { return "Çocuk" }
        if lower.contains("ulusal") || lower.contains("turkey") || lower.contains("türkiye") || lower.contains("genel") { return "Ulusal Kanallar" }

        return trimmed.prefix(1).uppercased() + trimmed.dropFirst()
    }

    private static func matchFirst(in text: String, regex: NSRegularExpression) -> String? {
        let range = NSRange(location: 0, length: text.utf16.count)
        guard let match = regex.firstMatch(in: text, range: range) else { return nil }
        if match.numberOfRanges > 1 {
            let capturedRange = match.range(at: 1)
            if let swiftRange = Range(capturedRange, in: text) {
                return String(text[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return nil
    }
}
