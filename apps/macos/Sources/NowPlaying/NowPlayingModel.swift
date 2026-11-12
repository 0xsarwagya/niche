import AppKit
import Observation

/// Observable now-playing state fed by a NowPlayingSource, with artwork fetched on track
/// change and playback actions routed to a MediaController. Lives on the main actor.
@MainActor
@Observable
final class NowPlayingModel {
    private(set) var current: NowPlaying?
    private(set) var artwork: NSImage?
    var isHovered = false

    private let controller: any MediaController
    private let artworkSource: any ArtworkSource
    private var streamTask: Task<Void, Never>?
    private var artworkTask: Task<Void, Never>?

    init(controller: any MediaController, artworkSource: any ArtworkSource) {
        self.controller = controller
        self.artworkSource = artworkSource
    }

    func start(source: some NowPlayingSource) {
        streamTask?.cancel()
        streamTask = Task { [weak self] in
            for await value in source.updates {
                guard let self else { break }
                let trackChanged = value?.title != self.current?.title
                self.current = value
                if value == nil {
                    self.artwork = nil
                } else if trackChanged {
                    self.loadArtwork()
                }
            }
        }
    }

    func stop() {
        streamTask?.cancel()
        streamTask = nil
        artworkTask?.cancel()
        artworkTask = nil
    }

    func togglePlayPause() { Task { await controller.togglePlayPause() } }
    func nextTrack() { Task { await controller.nextTrack() } }
    func previousTrack() { Task { await controller.previousTrack() } }

    private func loadArtwork() {
        artwork = nil
        artworkTask?.cancel()
        artworkTask = Task { [weak self] in
            for _ in 0..<3 {
                guard let self else { return }
                if let data = await self.artworkSource.currentArtwork(), let image = NSImage(data: data) {
                    self.artwork = image
                    return
                }
                try? await Task.sleep(for: .milliseconds(600))
            }
        }
    }
}
