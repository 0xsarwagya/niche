import Foundation

/// Loads user-defined weather adapters from Application Support, dropping any that fail validation.
enum WeatherProviderStore {
    static var configURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appending(path: "Niche/weather-providers.json")
    }

    static func load() -> [DeclarativeWeatherProvider] {
        guard let data = try? Data(contentsOf: configURL),
              let providers = try? JSONDecoder().decode([DeclarativeWeatherProvider].self, from: data) else {
            return []
        }
        return providers.filter(\.isValid)
    }
}
