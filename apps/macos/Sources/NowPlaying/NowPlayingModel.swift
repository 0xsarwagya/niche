import AppKit
import Observation
import SwiftUI

/// Observable now-playing state fed by a NowPlayingSource: artwork fetched on track change,
/// a locally-advancing elapsed time for the scrubber, and playback actions routed to a
/// MediaController. Lives on the main actor.
@MainActor
@Observable
final class NowPlayingModel {
    private(set) var current: NowPlaying?
    private(set) var artwork: NSImage?
    private(set) var accentColor: Color?
    private(set) var displayElapsed: TimeInterval = 0
    private(set) var hud: SystemLevel?
    private(set) var timerRemaining: TimeInterval?
    private(set) var timerTotal: TimeInterval = 0
    var isHovered = false

    private let controller: any MediaController
    private let artworkSource: any ArtworkSource
    private var streamTask: Task<Void, Never>?
    private var artworkTask: Task<Void, Never>?
    private var tickerTask: Task<Void, Never>?
    private var levelsTasks: [Task<Void, Never>] = []
    private var hudTask: Task<Void, Never>?
    private var countdownTask: Task<Void, Never>?

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

    func observeLevels(_ source: some SystemLevelsSource) {
        let task = Task { [weak self] in
            for await level in source.updates {
                guard let self else { break }
                self.presentHUD(level)
            }
        }
        levelsTasks.append(task)
    }

    func stop() {
        streamTask?.cancel()
        streamTask = nil
        artworkTask?.cancel()
        artworkTask = nil
        tickerTask?.cancel()
        tickerTask = nil
        levelsTasks.forEach { $0.cancel() }
        levelsTasks.removeAll()
        hudTask?.cancel()
        hudTask = nil
        countdownTask?.cancel()
        countdownTask = nil
    }

    func showLevel(_ level: SystemLevel) {
        presentHUD(level)
    }

    private func presentHUD(_ level: SystemLevel) {
        hud = level
        hudTask?.cancel()
        hudTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(1400))
            guard let self else { return }
            self.hud = nil
        }
    }

    func togglePlayPause() { Task { await controller.togglePlayPause() } }
    func nextTrack() { Task { await controller.nextTrack() } }
    func previousTrack() { Task { await controller.previousTrack() } }

    func seek(to seconds: TimeInterval) {
        displayElapsed = seconds
        Task { await controller.seek(toMicros: Int(seconds * 1_000_000)) }
    }

    func startTimer(_ duration: TimeInterval) {
        timerTotal = duration
        timerRemaining = duration
        countdownTask?.cancel()
        countdownTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self, let remaining = self.timerRemaining else { return }
                if remaining <= 1 {
                    self.timerRemaining = 0
                    try? await Task.sleep(for: .seconds(2))
                    self.timerRemaining = nil
                    return
                }
                self.timerRemaining = remaining - 1
            }
        }
    }

    func cancelTimer() {
        countdownTask?.cancel()
        countdownTask = nil
        timerRemaining = nil
    }

    private func apply(_ value: NowPlaying?) {
        let trackChanged = value?.title != current?.title
        current = value
        displayElapsed = value?.elapsed ?? 0
        if value == nil {
            artwork = nil
            accentColor = nil
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
        accentColor = nil
        artworkTask?.cancel()
        artworkTask = Task { [weak self] in
            for _ in 0..<3 {
                guard let self else { return }
                if let data = await self.artworkSource.currentArtwork(), let image = NSImage(data: data) {
                    self.artwork = image
                    self.accentColor = ArtworkColor.accent(from: image).map { Color(nsColor: $0) }
                    return
                }
                try? await Task.sleep(for: .milliseconds(600))
            }
        }
    }
}
