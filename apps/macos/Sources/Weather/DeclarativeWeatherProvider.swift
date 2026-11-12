import Foundation

/// A user-defined weather adapter: a URL template with `{lat}`/`{lon}`, API-key placement, and a
/// response field mapping (dot-paths). Conforms to WeatherProvider so the glance code is unchanged.
/// Config is untrusted: requests are validated (https only, non-local host) and the key — read from
/// the Keychain, never the JSON — is sent only to the adapter's own host.
struct DeclarativeWeatherProvider: WeatherProvider, Codable, Sendable {
    let id: String
    let name: String
    let url: String
    let keyParam: String?
    let keyHeader: String?
    let map: FieldMap

    struct FieldMap: Codable, Sendable {
        let temperature: String
        let condition: String
        let observedAt: String?
    }

    private static let maxResponseBytes = 256 * 1024
    private static let timeout: TimeInterval = 8

    var needsKey: Bool { keyParam != nil || keyHeader != nil }

    /// Valid when it builds a secure request; used to drop malformed adapters on load (fail closed).
    var isValid: Bool {
        (try? makeRequest(latitude: 0, longitude: 0, apiKey: nil)) != nil
    }

    func current(latitude: Double, longitude: Double) async throws -> WeatherSnapshot {
        let request = try makeRequest(latitude: latitude, longitude: longitude, apiKey: Keychain.key(for: id))
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw WeatherError.invalidResponse }
        guard http.statusCode == 200 else { throw WeatherError.http(status: http.statusCode) }
        guard data.count <= Self.maxResponseBytes else { throw WeatherError.responseTooLarge }
        let json = try JSONSerialization.jsonObject(with: data)
        guard let temperature = Self.double(at: map.temperature, in: json) else { throw WeatherError.mappingFailed }
        let condition = Self.int(at: map.condition, in: json) ?? 0
        return WeatherSnapshot(temperatureCelsius: temperature, conditionCode: condition, observedAt: .now)
    }

    func makeRequest(latitude: Double, longitude: Double, apiKey: String?) throws -> URLRequest {
        let filled = url
            .replacingOccurrences(of: "{lat}", with: String(latitude))
            .replacingOccurrences(of: "{lon}", with: String(longitude))
        guard var components = URLComponents(string: filled) else { throw WeatherError.invalidURL }
        guard components.scheme?.lowercased() == "https" else { throw WeatherError.insecureURL }
        guard let host = components.host?.lowercased(), !Self.isLocalHost(host) else { throw WeatherError.insecureURL }
        if let keyParam, let apiKey {
            var items = components.queryItems ?? []
            items.append(URLQueryItem(name: keyParam, value: apiKey))
            components.queryItems = items
        }
        guard let finalURL = components.url else { throw WeatherError.invalidURL }
        var request = URLRequest(url: finalURL, timeoutInterval: Self.timeout)
        if let keyHeader, let apiKey {
            request.setValue(apiKey, forHTTPHeaderField: keyHeader)
        }
        return request
    }

    static func isLocalHost(_ host: String) -> Bool {
        host == "localhost" || host == "127.0.0.1" || host == "::1" || host.hasSuffix(".local")
    }

    static func value(at path: String, in json: Any) -> Any? {
        var current: Any? = json
        for part in path.split(separator: ".") {
            if let index = Int(part), let array = current as? [Any], index >= 0, index < array.count {
                current = array[index]
            } else if let dictionary = current as? [String: Any] {
                current = dictionary[String(part)]
            } else {
                return nil
            }
        }
        return current
    }

    static func double(at path: String, in json: Any) -> Double? {
        switch value(at: path, in: json) {
        case let number as NSNumber: number.doubleValue
        case let string as String: Double(string)
        default: nil
        }
    }

    static func int(at path: String, in json: Any) -> Int? {
        switch value(at: path, in: json) {
        case let number as NSNumber: number.intValue
        case let string as String: Int(string)
        default: nil
        }
    }
}
