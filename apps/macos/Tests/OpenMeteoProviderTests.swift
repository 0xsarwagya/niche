import Foundation
import Testing
@testable import Niche

struct OpenMeteoProviderTests {
    @Test func requestTargetsOpenMeteoForecast() throws {
        let url = try #require(OpenMeteoProvider.request(latitude: 52.52, longitude: 13.41).url)
        #expect(url.absoluteString.hasPrefix("https://api.open-meteo.com/v1/forecast"))
    }

    @Test func requestCarriesLatitude() throws {
        let url = try #require(OpenMeteoProvider.request(latitude: 52.52, longitude: 13.41).url)
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(items.contains(URLQueryItem(name: "latitude", value: "52.52")))
    }

    @Test func requestAsksForDailyHighLow() throws {
        let url = try #require(OpenMeteoProvider.request(latitude: 52.52, longitude: 13.41).url)
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(items.contains(URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min")))
    }
}
