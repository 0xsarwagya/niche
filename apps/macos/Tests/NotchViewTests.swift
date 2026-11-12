import Testing
@testable import Niche

struct NotchViewTests {
    @Test func formatsMinutesAndSeconds() {
        #expect(NotchView.format(125) == "2:05")
    }

    @Test func formatsZero() {
        #expect(NotchView.format(0) == "0:00")
    }
}
