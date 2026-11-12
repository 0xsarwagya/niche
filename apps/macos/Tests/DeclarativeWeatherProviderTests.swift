import Foundation
import Testing
@testable import Niche

struct DeclarativeWeatherProviderTests {
    private func sample(
        url: String = "https://api.example.com/w?lat={lat}&lon={lon}",
        keyParam: String? = "appid",
        keyHeader: String? = nil
    ) -> DeclarativeWeatherProvider {
        DeclarativeWeatherProvider(
            id: "x", name: "X", url: url, keyParam: keyParam, keyHeader: keyHeader,
            map: .init(temperature: "main.temp", condition: "weather.0.id", observedAt: nil)
        )
    }

    @Test func mapsNestedTemperature() throws {
        let json = try JSONSerialization.jsonObject(with: Data(#"{"main":{"temp":12.5}}"#.utf8))
        #expect(DeclarativeWeatherProvider.double(at: "main.temp", in: json) == 12.5)
    }

    @Test func mapsArrayCondition() throws {
        let json = try JSONSerialization.jsonObject(with: Data(#"{"weather":[{"id":802}]}"#.utf8))
        #expect(DeclarativeWeatherProvider.int(at: "weather.0.id", in: json) == 802)
    }

    @Test func keyGoesInQueryParam() throws {
        let request = try sample().makeRequest(latitude: 1, longitude: 2, apiKey: "secret")
        let items = URLComponents(url: try #require(request.url), resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(items.contains(URLQueryItem(name: "appid", value: "secret")))
    }

    @Test func keyGoesInHeader() throws {
        let request = try sample(keyParam: nil, keyHeader: "X-Api-Key")
            .makeRequest(latitude: 1, longitude: 2, apiKey: "secret")
        #expect(request.value(forHTTPHeaderField: "X-Api-Key") == "secret")
    }

    @Test func httpURLRejected() {
        #expect(throws: WeatherError.self) {
            try sample(url: "http://api.example.com/w?lat={lat}&lon={lon}", keyParam: nil)
                .makeRequest(latitude: 1, longitude: 2, apiKey: nil)
        }
    }

    @Test func localhostRejected() {
        #expect(throws: WeatherError.self) {
            try sample(url: "https://localhost/w?lat={lat}&lon={lon}", keyParam: nil)
                .makeRequest(latitude: 1, longitude: 2, apiKey: nil)
        }
    }
}
