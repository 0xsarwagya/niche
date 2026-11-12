import Testing
@testable import Niche

struct MediaRemoteNowPlayingSourceTests {
    @Test func parsesPlayingTrackFromStreamLine() throws {
        let line = #"{"type":"data","diff":false,"payload":{"title":"Golden Hour","artist":"Elias Vale","playing":true}}"#
        let track = try #require(MediaRemoteNowPlayingSource.nowPlaying(fromStreamLine: line))
        #expect(track == NowPlaying(title: "Golden Hour", artist: "Elias Vale", isPlaying: true))
    }

    @Test func emptyPayloadMeansNothingPlaying() {
        let line = #"{"type":"data","diff":false,"payload":{}}"#
        #expect(MediaRemoteNowPlayingSource.nowPlaying(fromStreamLine: line) == nil)
    }
}
