import Testing
@testable import Niche

struct MediaKeyTests {
    @Test func volumeUpIsCodeZero() {
        #expect(MediaKey.forKeyCode(0) == .volumeUp)
    }

    @Test func muteIsCodeSeven() {
        #expect(MediaKey.forKeyCode(7) == .mute)
    }

    @Test func unknownCodeIsNil() {
        #expect(MediaKey.forKeyCode(99) == nil)
    }
}
