import SwiftUI
import Observation

/// User-tunable settings, persisted to UserDefaults. Views read `.shared` and update live.
@MainActor
@Observable
final class Preferences {
    static let shared = Preferences()

    var showNowPlaying: Bool { didSet { store.set(showNowPlaying, forKey: Key.showNowPlaying) } }
    var showWeather: Bool { didSet { store.set(showWeather, forKey: Key.showWeather) } }
    var showHUD: Bool { didSet { store.set(showHUD, forKey: Key.showHUD) } }
    var showBattery: Bool { didSet { store.set(showBattery, forKey: Key.showBattery) } }
    var hudSeconds: Double { didSet { store.set(hudSeconds, forKey: Key.hudSeconds) } }
    var useCustomAccent: Bool { didSet { store.set(useCustomAccent, forKey: Key.useCustomAccent) } }
    var customAccent: Color { didSet { store.set(customAccent.rgbComponents, forKey: Key.customAccent) } }

    private let store: UserDefaults

    init(store: UserDefaults = .standard) {
        self.store = store
        showNowPlaying = store.object(forKey: Key.showNowPlaying) as? Bool ?? true
        showWeather = store.object(forKey: Key.showWeather) as? Bool ?? true
        showHUD = store.object(forKey: Key.showHUD) as? Bool ?? true
        showBattery = store.object(forKey: Key.showBattery) as? Bool ?? true
        hudSeconds = store.object(forKey: Key.hudSeconds) as? Double ?? 1.4
        useCustomAccent = store.object(forKey: Key.useCustomAccent) as? Bool ?? false
        if let rgb = store.array(forKey: Key.customAccent) as? [Double], rgb.count == 3 {
            customAccent = Color(red: rgb[0], green: rgb[1], blue: rgb[2])
        } else {
            customAccent = Preferences.defaultAccent
        }
    }

    static let defaultAccent = Color(red: 0.78, green: 0.97, blue: 0.32)

    private enum Key {
        static let showNowPlaying = "showNowPlaying"
        static let showWeather = "showWeather"
        static let showHUD = "showHUD"
        static let showBattery = "showBattery"
        static let hudSeconds = "hudSeconds"
        static let useCustomAccent = "useCustomAccent"
        static let customAccent = "customAccent"
    }
}

extension Color {
    var rgbComponents: [Double] {
        let srgb = NSColor(self).usingColorSpace(.sRGB) ?? .white
        return [Double(srgb.redComponent), Double(srgb.greenComponent), Double(srgb.blueComponent)]
    }
}
