import Foundation
import os

/// Sends playback commands through the vendored mediaremote-adapter (`send COMMAND`).
struct MediaRemoteController: MediaController {
    private static let logger = Logger(subsystem: "com.niche.app", category: "MediaRemoteController")

    /// MRCommand identifiers from the mediaremote-adapter CLI.
    enum Command: Int {
        case togglePlayPause = 2
        case nextTrack = 4
        case previousTrack = 5
    }

    func togglePlayPause() async { send(.togglePlayPause) }
    func nextTrack() async { send(.nextTrack) }
    func previousTrack() async { send(.previousTrack) }

    private func send(_ command: Command) {
        guard let adapter = MediaRemoteAdapter.paths() else {
            Self.logger.error("adapter missing; cannot send command")
            return
        }
        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/perl")
        process.arguments = Self.arguments(for: command, script: adapter.script.path, framework: adapter.framework.path)
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            Self.logger.error("send \(command.rawValue, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    static func arguments(for command: Command, script: String, framework: String) -> [String] {
        [script, framework, "send", String(command.rawValue)]
    }
}
