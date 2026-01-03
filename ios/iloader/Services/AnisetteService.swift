/// AnisetteService provides authentication data required for Apple services.
/// Communicates with Anisette V3 servers (like omnisette, SideStore's server, etc.)
import Foundation

class AnisetteService {
    static let shared = AnisetteService()

    /// Anisette headers needed for Apple authentication
    struct AnisetteData: Codable {
        let machineID: String
        let oneTimePassword: String
        let localUserID: String
        let routingInfo: String
        let deviceUniqueIdentifier: String
        let deviceSerialNumber: String
        let deviceDescription: String
        let date: String
        let locale: String
        let timezone: String

        enum CodingKeys: String, CodingKey {
            case machineID = "X-Apple-I-MD-M"
            case oneTimePassword = "X-Apple-I-MD"
            case localUserID = "X-Apple-I-MD-LU"
            case routingInfo = "X-Apple-I-MD-RINFO"
            case deviceUniqueIdentifier = "X-Mme-Device-Id"
            case deviceSerialNumber = "X-Apple-I-SRL-NO"
            case deviceDescription = "X-MMe-Client-Info"
            case date = "X-Apple-I-Client-Time"
            case locale = "X-Apple-Locale"
            case timezone = "X-Apple-I-TimeZone"
        }

        /// Convert to dictionary for URLRequest headers
        func toHeaders() -> [String: String] {
            return [
                "X-Apple-I-MD-M": machineID,
                "X-Apple-I-MD": oneTimePassword,
                "X-Apple-I-MD-LU": localUserID,
                "X-Apple-I-MD-RINFO": routingInfo,
                "X-Mme-Device-Id": deviceUniqueIdentifier,
                "X-Apple-I-SRL-NO": deviceSerialNumber,
                "X-MMe-Client-Info": deviceDescription,
                "X-Apple-I-Client-Time": date,
                "X-Apple-Locale": locale,
                "X-Apple-I-TimeZone": timezone,
            ]
        }
    }

    private var cachedData: AnisetteData?
    private var cacheExpiry: Date = .distantPast

    /// Fetch Anisette headers from server
    /// Most Anisette servers return JSON with the required headers
    func fetchAnisetteHeaders(serverUrl: String) async throws -> [String: String] {
        // Check cache (Anisette data is typically valid for ~5 minutes)
        if let cached = cachedData, Date() < cacheExpiry {
            return cached.toHeaders()
        }

        // Build URL - most servers use /headers or /anisette endpoint
        var urlString = serverUrl
        if !urlString.hasPrefix("http") {
            urlString = "https://\(urlString)"
        }

        // Try common endpoints
        let endpoints = ["", "/headers", "/anisette"]
        var lastError: Error?

        for endpoint in endpoints {
            guard let url = URL(string: urlString + endpoint) else { continue }

            do {
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.timeoutInterval = 15
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                request.setValue("iloader/1.0", forHTTPHeaderField: "User-Agent")

                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse,
                    httpResponse.statusCode == 200
                else {
                    continue
                }

                // Try to decode as AnisetteData
                let decoder = JSONDecoder()

                // Some servers return headers directly, others nest them
                if let anisetteData = try? decoder.decode(AnisetteData.self, from: data) {
                    self.cachedData = anisetteData
                    self.cacheExpiry = Date().addingTimeInterval(300)  // 5 min cache
                    return anisetteData.toHeaders()
                }

                // Try parsing as generic dictionary
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    var headers: [String: String] = [:]

                    // Extract known header keys
                    let headerKeys = [
                        "X-Apple-I-MD-M", "X-Apple-I-MD", "X-Apple-I-MD-LU",
                        "X-Apple-I-MD-RINFO", "X-Mme-Device-Id", "X-Apple-I-SRL-NO",
                        "X-MMe-Client-Info", "X-Apple-I-Client-Time", "X-Apple-Locale",
                        "X-Apple-I-TimeZone",
                    ]

                    for key in headerKeys {
                        if let value = json[key] as? String {
                            headers[key] = value
                        }
                    }

                    if !headers.isEmpty {
                        return headers
                    }
                }
            } catch {
                lastError = error
                continue
            }
        }

        throw lastError
            ?? NSError(
                domain: "AnisetteService",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "Failed to fetch Anisette data from \(serverUrl)"
                ]
            )
    }

    /// Clear cached Anisette data
    func invalidateCache() {
        cachedData = nil
        cacheExpiry = .distantPast
    }
}
