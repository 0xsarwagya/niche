import Testing
@testable import Niche

struct NotchViewTests {
    @Test func formatsMinutesAndSeconds() {
        #expect(NotchView.format(125) == "2:05")
    }

    @Test func formatsZero() {
        #expect(NotchView.format(0) == "0:00")
    }

    @Test func weatherTextForClear() {
        #expect(NotchView.weatherText(0) == "Clear")
    }

    @Test func weatherTextForRain() {
        #expect(NotchView.weatherText(63) == "Rain")
    }
}
