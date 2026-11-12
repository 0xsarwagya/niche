import Testing
@testable import Niche

struct MediaRemoteControllerTests {
    @Test func togglePlayPauseMapsToSendCommandTwo() {
        let args = MediaRemoteController.arguments(for: .togglePlayPause, script: "s.pl", framework: "f.framework")
        #expect(args == ["s.pl", "f.framework", "send", "2"])
    }

    @Test func nextTrackIsCommandFour() {
        #expect(MediaRemoteController.Command.nextTrack.rawValue == 4)
    }
}
