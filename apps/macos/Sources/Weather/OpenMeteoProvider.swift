import Foundation
import os

/// Keyless default weather provider backed by the free Open-Meteo API.
struct OpenMeteoProvider: WeatherProvider {
    private static let logger = Logger(subsystem: "com.niche.app", category: "OpenMeteoProvider")
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func current(latitude: Double, longitude: Double) async throws -> WeatherSnapshot {
        let (data, response) = try await session.data(for: Self.request(latitude: latitude, longitude: longitude))
        guard let http = response as? HTTPURLResponse else {
            throw WeatherError.invalidResponse
        }
        guard http.statusCode == 200 else {
            throw WeatherError.http(status: http.statusCode)
        }
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        return WeatherSnapshot(
            temperatureCelsius: decoded.current.temperature,
            conditionCode: decoded.current.weatherCode,
            observedAt: .now,
            highCelsius: decoded.daily?.max.first,
            lowCelsius: decoded.daily?.min.first
        )
    }

    static func request(latitude: Double, longitude: Double) -> URLRequest {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code"),
            URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "1"),
        ]
        return URLRequest(url: components.url!)
    }
}

enum WeatherError: Error, Equatable {
    case invalidResponse
    case http(status: Int)
    case invalidURL
    case insecureURL
    case responseTooLarge
    case mappingFailed
}

private extension OpenMeteoProvider {
    struct Response: Decodable {
        let current: Current
        let daily: Daily?

        struct Current: Decodable {
            let temperature: Double
            let weatherCode: Int

            enum CodingKeys: String, CodingKey {
                case temperature = "temperature_2m"
                case weatherCode = "weather_code"
            }
        }

        struct Daily: Decodable {
            let max: [Double]
            let min: [Double]

            enum CodingKeys: String, CodingKey {
                case max = "temperature_2m_max"
                case min = "temperature_2m_min"
            }
        }
    }
}
