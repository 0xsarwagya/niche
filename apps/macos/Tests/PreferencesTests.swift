import Testing
import SwiftUI
@testable import Niche

@MainActor
struct PreferencesTests {
    private func freshStore() -> UserDefaults {
        UserDefaults(suiteName: "niche.test.\(UUID().uuidString)")!
    }

    @Test func defaultHudSeconds() {
        #expect(Preferences(store: freshStore()).hudSeconds == 1.4)
    }

    @Test func modulesDefaultOn() {
        #expect(Preferences(store: freshStore()).showNowPlaying)
    }

    @Test func persistsToggle() {
        let store = freshStore()
        Preferences(store: store).showHUD = false
        #expect(!Preferences(store: store).showHUD)
    }

    @Test func persistsHudSeconds() {
        let store = freshStore()
        Preferences(store: store).hudSeconds = 2.5
        #expect(Preferences(store: store).hudSeconds == 2.5)
    }

    @Test func persistsCustomAccent() {
        let store = freshStore()
        Preferences(store: store).customAccent = Color(red: 0.2, green: 0.4, blue: 0.6)
        let rgb = NSColor(Preferences(store: store).customAccent).usingColorSpace(.sRGB)!
        let matches = abs(rgb.redComponent - 0.2) < 0.02
            && abs(rgb.greenComponent - 0.4) < 0.02
            && abs(rgb.blueComponent - 0.6) < 0.02
        #expect(matches)
    }
}
