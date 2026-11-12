import Foundation
import os

/// Fetches the current track's artwork bytes via the adapter's one-shot `get`.
struct MediaRemoteArtworkSource: ArtworkSource {
    private static let logger = Logger(subsystem: "com.niche.app", category: "MediaRemoteArtworkSource")

    func currentArtwork() async -> Data? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                continuation.resume(returning: Self.fetch())
            }
        }
    }

    private static func fetch() -> Data? {
        guard let adapter = MediaRemoteAdapter.paths() else { return nil }
        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/perl")
        process.arguments = [adapter.script.path, adapter.framework.path, "get"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            logger.error("artwork get failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
        let output = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return artworkData(fromGetOutput: output)
    }

    static func artworkData(fromGetOutput output: Data) -> Data? {
        guard let payload = try? JSONDecoder().decode(Payload.self, from: output),
              let base64 = payload.artworkData else { return nil }
        return Data(base64Encoded: base64)
    }

    struct Payload: Decodable {
        let artworkData: String?
    }
}
