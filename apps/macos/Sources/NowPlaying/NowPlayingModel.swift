import Observation

/// Observable now-playing state fed by a NowPlayingSource, with playback actions
/// routed to a MediaController. Lives on the main actor.
@MainActor
@Observable
final class NowPlayingModel {
    private(set) var current: NowPlaying?
    var isHovered = false

    private let controller: any MediaController
    private var task: Task<Void, Never>?

    init(controller: any MediaController) {
        self.controller = controller
    }

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

    func togglePlayPause() { Task { await controller.togglePlayPause() } }
    func nextTrack() { Task { await controller.nextTrack() } }
    func previousTrack() { Task { await controller.previousTrack() } }
}
