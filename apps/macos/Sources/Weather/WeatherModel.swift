import Observation

/// Observable weather state. Opt-in via `enable()`, which resolves the location once and then
/// refreshes the snapshot from the WeatherProvider on an interval.
@MainActor
@Observable
final class WeatherModel {
    private(set) var snapshot: WeatherSnapshot?

    private let provider: any WeatherProvider
    private let location: LocationProvider
    private var task: Task<Void, Never>?

    init(provider: any WeatherProvider, location: LocationProvider) {
        self.provider = provider
        self.location = location
    }

    func enable() {
        task?.cancel()
        task = Task { [weak self] in
            guard let self, let coordinate = await self.location.current() else { return }
            while !Task.isCancelled {
                if let snapshot = try? await self.provider.current(
                    latitude: coordinate.latitude, longitude: coordinate.longitude
                ) {
                    self.snapshot = snapshot
                }
                try? await Task.sleep(for: .seconds(900))
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }
}
