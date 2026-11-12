import Observation

/// Observable now-playing state, fed by a NowPlayingSource on the main actor.
@MainActor
@Observable
final class NowPlayingModel {
    private(set) var current: NowPlaying?
    private var task: Task<Void, Never>?

    func start(source: some NowPlayingSource) {
        task?.cancel()
        task = Task { [weak self] in
            for await value in source.updates {
                self?.current = value
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }
}
