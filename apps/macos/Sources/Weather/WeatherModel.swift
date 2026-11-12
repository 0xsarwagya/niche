import CoreLocation
import Observation

/// Observable weather state. Opt-in via `enable()` (resolves location once, then refreshes from the
/// active provider on an interval). `setProvider` swaps the active source without re-prompting location.
@MainActor
@Observable
final class WeatherModel {
    private(set) var snapshot: WeatherSnapshot?

    private var activeProvider: any WeatherProvider
    private let location: LocationProvider
    private var coordinate: CLLocationCoordinate2D?
    private var task: Task<Void, Never>?

    init(defaultProvider: any WeatherProvider, location: LocationProvider) {
        self.activeProvider = defaultProvider
        self.location = location
    }

    func enable() {
        task?.cancel()
        task = Task { [weak self] in
            guard let self else { return }
            if self.coordinate == nil {
                self.coordinate = await self.location.current()
            }
            guard self.coordinate != nil else { return }
            await self.refreshLoop()
        }
    }

    func setProvider(_ provider: any WeatherProvider) {
        activeProvider = provider
        snapshot = nil
        guard coordinate != nil else { return }
        task?.cancel()
        task = Task { [weak self] in await self?.refreshLoop() }
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    private func refreshLoop() async {
        guard let coordinate else { return }
        while !Task.isCancelled {
            if let snapshot = try? await activeProvider.current(
                latitude: coordinate.latitude, longitude: coordinate.longitude
            ) {
                self.snapshot = snapshot
            }
            try? await Task.sleep(for: .seconds(900))
        }
    }
}
