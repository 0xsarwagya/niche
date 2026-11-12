import Foundation
import os

/// NowPlayingSource backed by the vendored ungive/mediaremote-adapter: it spawns the
/// Apple-signed /usr/bin/perl with the helper framework and parses its JSON stream,
/// the only route to now-playing on macOS 15.4+.
struct MediaRemoteNowPlayingSource: NowPlayingSource {
    private static let logger = Logger(subsystem: "com.niche.app", category: "MediaRemoteNowPlayingSource")

    var updates: AsyncStream<NowPlaying?> {
        AsyncStream { continuation in
            guard let adapter = MediaRemoteAdapter.paths() else {
                Self.logger.error("mediaremote-adapter missing from the app bundle")
                continuation.finish()
                return
            }

            let process = Process()
            process.executableURL = URL(filePath: "/usr/bin/perl")
            process.arguments = [
                adapter.script.path, adapter.framework.path,
                "stream", "--no-diff", "--no-artwork",
            ]
            let output = Pipe()
            process.standardOutput = output
            process.standardError = FileHandle.nullDevice

            continuation.onTermination = { _ in
                if process.isRunning { process.terminate() }
            }

            Task {
                do {
                    for try await line in output.fileHandleForReading.bytes.lines {
                        continuation.yield(Self.nowPlaying(fromStreamLine: line))
                    }
                } catch {
                    Self.logger.error("adapter stream read failed: \(error.localizedDescription, privacy: .public)")
                }
                continuation.finish()
            }

            do {
                try process.run()
                Self.logger.info("mediaremote-adapter stream started")
            } catch {
                Self.logger.error("failed to start adapter: \(error.localizedDescription, privacy: .public)")
                continuation.finish()
            }
        }
    }

    static func nowPlaying(fromStreamLine line: String) -> NowPlaying? {
        guard let data = line.data(using: .utf8),
              let envelope = try? JSONDecoder().decode(StreamLine.self, from: data) else {
            return nil
        }
        return nowPlaying(from: envelope.payload)
    }

    static func nowPlaying(from payload: Payload) -> NowPlaying? {
        guard let title = payload.title, !title.isEmpty else { return nil }
        return NowPlaying(title: title, artist: payload.artist ?? "", isPlaying: payload.playing ?? false)
    }

    struct StreamLine: Decodable {
        let payload: Payload
    }

    struct Payload: Decodable {
        let title: String?
        let artist: String?
        let playing: Bool?
    }
}
