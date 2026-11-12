import Foundation

/// Currently playing media, source-agnostic.
struct NowPlaying: Equatable, Sendable {
    let title: String
    let artist: String
    let isPlaying: Bool
}
