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

    @Test func promptWinsOverEverything() {
        #expect(NotchGeometry.content(prompt: true, status: true, hasTrack: true, hud: true, timer: true, weather: true) == .prompt)
    }

    @Test func hudWinsOverTrack() {
        #expect(NotchGeometry.content(prompt: false, status: false, hasTrack: true, hud: true, timer: true, weather: true) == .hud)
    }

    @Test func timerWinsOverTrack() {
        #expect(NotchGeometry.content(prompt: false, status: false, hasTrack: true, hud: false, timer: true, weather: false) == .timer)
    }

    @Test func weatherShowsOnlyWhenIdle() {
        #expect(NotchGeometry.content(prompt: false, status: false, hasTrack: false, hud: false, timer: false, weather: true) == .weather)
    }

    @Test func trackWinsOverWeather() {
        #expect(NotchGeometry.content(prompt: false, status: false, hasTrack: true, hud: false, timer: false, weather: true) == .nowPlaying)
    }

    @Test func statusShowsOverTrack() {
        #expect(NotchGeometry.content(prompt: false, status: true, hasTrack: true, hud: false, timer: false, weather: false) == .status)
    }

    @Test func expandedMediaRoundsMoreThanCompact() {
        #expect(NotchGeometry.cornerRadius(content: .nowPlaying, hovered: true)
            > NotchGeometry.cornerRadius(content: .nowPlaying, hovered: false))
    }

    @Test func promptRoundsMoreThanHud() {
        #expect(NotchGeometry.cornerRadius(content: .prompt, hovered: false)
            > NotchGeometry.cornerRadius(content: .hud, hovered: false))
    }

    @Test func idleHasNoShoulders() {
        #expect(NotchGeometry.shoulderRadius(content: .hidden) == 0)
    }

    @Test func expandedStatesHaveShoulders() {
        #expect(NotchGeometry.shoulderRadius(content: .nowPlaying) > 0)
        #expect(NotchGeometry.shoulderRadius(content: .prompt) > 0)
    }
}
