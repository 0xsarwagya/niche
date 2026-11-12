import AppKit
import Observation

/// Observable now-playing state fed by a NowPlayingSource: artwork fetched on track change,
/// a locally-advancing elapsed time for the scrubber, and playback actions routed to a
/// MediaController. Lives on the main actor.
@MainActor
@Observable
final class NowPlayingModel {
    private(set) var current: NowPlaying?
    private(set) var artwork: NSImage?
    private(set) var displayElapsed: TimeInterval = 0
    var isHovered = false

    private let controller: any MediaController
    private let artworkSource: any ArtworkSource
    private var streamTask: Task<Void, Never>?
    private var artworkTask: Task<Void, Never>?
    private var tickerTask: Task<Void, Never>?

    init(controller: any MediaController, artworkSource: any ArtworkSource) {
        self.controller = controller
        self.artworkSource = artworkSource
    }

    func start(source: some NowPlayingSource) {
        streamTask?.cancel()
        streamTask = Task { [weak self] in
            for await value in source.updates {
                guard let self else { break }
                self.apply(value)
            }
        }
        startTicker()
    }

    func stop() {
        streamTask?.cancel()
        streamTask = nil
        artworkTask?.cancel()
        artworkTask = nil
        tickerTask?.cancel()
        tickerTask = nil
    }

    func togglePlayPause() { Task { await controller.togglePlayPause() } }
    func nextTrack() { Task { await controller.nextTrack() } }
    func previousTrack() { Task { await controller.previousTrack() } }

    func seek(to seconds: TimeInterval) {
        displayElapsed = seconds
        Task { await controller.seek(toMicros: Int(seconds * 1_000_000)) }
    }

    private func apply(_ value: NowPlaying?) {
        let trackChanged = value?.title != current?.title
        current = value
        displayElapsed = value?.elapsed ?? 0
        if value == nil {
            artwork = nil
        } else if trackChanged {
            loadArtwork()
        }
    }

    private func startTicker() {
        tickerTask?.cancel()
        tickerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                guard let self else { return }
                guard let track = self.current, track.isPlaying, track.duration > 0 else { continue }
                self.displayElapsed = min(self.displayElapsed + 0.5, track.duration)
            }
        }
    }

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
