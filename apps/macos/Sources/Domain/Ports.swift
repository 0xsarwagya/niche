import Foundation

/// Source of now-playing media. The only adapter will wrap ungive/mediaremote-adapter;
/// isolating it here lets one adapter swap when Apple changes the private framework.
protocol NowPlayingSource: Sendable {
    var updates: AsyncStream<NowPlaying?> { get }
}

/// Weather seam. OpenMeteoProvider is the keyless default; bring-your-own providers
/// decode from user config behind this same protocol.
protocol WeatherProvider: Sendable {
    func current(latitude: Double, longitude: Double) async throws -> WeatherSnapshot
}

/// Controls playback on the now-playing application.
protocol MediaController: Sendable {
    func togglePlayPause() async
    func nextTrack() async
    func previousTrack() async
}
