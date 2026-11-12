import Foundation

/// Currently playing media, source-agnostic.
struct NowPlaying: Equatable, Sendable {
    let title: String
    let artist: String
    let isPlaying: Bool
    var duration: TimeInterval = 0
    var elapsed: TimeInterval = 0
}
