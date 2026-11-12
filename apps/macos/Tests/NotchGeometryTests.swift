import CoreGraphics
import Testing
@testable import Niche

struct NotchGeometryTests {
    @Test func panelIsCenteredAtTopEdge() {
        let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let frame = NotchGeometry.panelFrame(in: screen, size: CGSize(width: 200, height: 30))
        #expect(frame == CGRect(x: 620, y: 870, width: 200, height: 30))
    }

    @Test func idleIslandMatchesTheNotch() {
        let size = NotchGeometry.islandSize(content: .hidden, hovered: false, notch: .fake)
        #expect(size == CGSize(width: 200, height: 32))
    }

    @Test func hudWinsOverEverything() {
        #expect(NotchGeometry.content(hasTrack: true, hud: true, timer: true, weather: true) == .hud)
    }

    @Test func timerWinsOverTrack() {
        #expect(NotchGeometry.content(hasTrack: true, hud: false, timer: true, weather: false) == .timer)
    }

    @Test func weatherShowsOnlyWhenIdle() {
        #expect(NotchGeometry.content(hasTrack: false, hud: false, timer: false, weather: true) == .weather)
    }

    @Test func trackWinsOverWeather() {
        #expect(NotchGeometry.content(hasTrack: true, hud: false, timer: false, weather: true) == .nowPlaying)
    }
}
