import AppKit
import ApplicationServices
import os

/// Creates the notch panel and menu bar item on launch, and feeds the panel its state.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let logger = Logger(subsystem: "com.niche.app", category: "AppDelegate")
    private let nowPlaying = NowPlayingModel(
        controller: MediaRemoteController(),
        artworkSource: MediaRemoteArtworkSource()
    )
    private let weather = WeatherModel(defaultProvider: OpenMeteoProvider(), location: LocationProvider())
    private let configuredProviders = WeatherProviderStore.load()
    private var panel: NotchPanel?
    private var statusItem: NSStatusItem?
    private var mediaKeys: MediaKeyTap?
    private var mediaKeyTask: Task<Void, Never>?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let screen = NSScreen.main else {
            Self.logger.error("No main screen; cannot place the notch panel")
            return
        }
        nowPlaying.start(source: MediaRemoteNowPlayingSource())
        nowPlaying.observeLevels(SystemLevelsPoller())
        nowPlaying.observeLevels(BatteryMonitor())
        let panel = NotchPanel(screen: screen, model: nowPlaying, weather: weather)
        panel.orderFrontRegardless()
        self.panel = panel
        setUpMenuBar()
        setUpMediaKeys()
        Self.logger.info("Niche launched")
    }

    func applicationWillTerminate(_ notification: Notification) {
        nowPlaying.stop()
        weather.stop()
        mediaKeyTask?.cancel()
    }

    private func setUpMenuBar() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "Niche")
        image?.isTemplate = true
        item.button?.image = image

        let menu = NSMenu()

        let timerMenu = NSMenu()
        for minutes in [1, 5, 10, 25] {
            let entry = NSMenuItem(title: "\(minutes) min", action: #selector(startTimer(_:)), keyEquivalent: "")
            entry.target = self
            entry.tag = minutes
            timerMenu.addItem(entry)
        }
        let timerItem = NSMenuItem(title: "Start Timer", action: nil, keyEquivalent: "")
        timerItem.submenu = timerMenu
        menu.addItem(timerItem)

        let weatherItem = NSMenuItem(title: "Enable Weather", action: #selector(enableWeather), keyEquivalent: "")
        weatherItem.target = self
        menu.addItem(weatherItem)

        let sourceMenu = NSMenu()
        let defaultItem = NSMenuItem(title: "Open-Meteo (default)", action: #selector(selectProvider(_:)), keyEquivalent: "")
        defaultItem.target = self
        defaultItem.tag = 0
        sourceMenu.addItem(defaultItem)
        for (index, provider) in configuredProviders.enumerated() {
            let entry = NSMenuItem(title: provider.name, action: #selector(selectProvider(_:)), keyEquivalent: "")
            entry.target = self
            entry.tag = index + 1
            sourceMenu.addItem(entry)
        }
        let sourceItem = NSMenuItem(title: "Weather Source", action: nil, keyEquivalent: "")
        sourceItem.submenu = sourceMenu
        menu.addItem(sourceItem)

        menu.addItem(.separator())

        let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLogin(_:)), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = LoginItem.isEnabled ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Niche", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        item.menu = menu
        statusItem = item
    }

    @objc private func startTimer(_ sender: NSMenuItem) {
        nowPlaying.startTimer(TimeInterval(sender.tag * 60))
    }

    @objc private func enableWeather() {
        weather.enable()
    }

    @objc private func selectProvider(_ sender: NSMenuItem) {
        guard sender.tag > 0 else {
            weather.setProvider(OpenMeteoProvider())
            return
        }
        let provider = configuredProviders[sender.tag - 1]
        if provider.needsKey, Keychain.key(for: provider.id) == nil {
            guard let key = promptForKey(provider) else { return }
            Keychain.setKey(key, for: provider.id)
        }
        weather.setProvider(provider)
    }

    @objc private func toggleLogin(_ sender: NSMenuItem) {
        LoginItem.toggle()
        sender.state = LoginItem.isEnabled ? .on : .off
    }

    private func setUpMediaKeys() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        guard AXIsProcessTrustedWithOptions(options) else {
            Self.logger.info("Accessibility not granted; system volume/brightness OSD not suppressed")
            return
        }
        let tap = MediaKeyTap()
        guard tap.start() else { return }
        mediaKeys = tap
        let keys = tap.keys
        mediaKeyTask = Task { [weak self] in
            for await key in keys {
                self?.handleMediaKey(key)
            }
        }
    }

    private func handleMediaKey(_ key: MediaKey) {
        let step = 1.0 / 16
        switch key {
        case .volumeUp:
            nowPlaying.showLevel(SystemLevel(kind: .volume, value: SystemControls.adjustVolume(by: step)))
        case .volumeDown:
            nowPlaying.showLevel(SystemLevel(kind: .volume, value: SystemControls.adjustVolume(by: -step)))
        case .mute:
            nowPlaying.showLevel(SystemLevel(kind: .volume, value: SystemControls.toggleMute()))
        case .brightnessUp:
            nowPlaying.showLevel(SystemLevel(kind: .brightness, value: SystemControls.adjustBrightness(by: step)))
        case .brightnessDown:
            nowPlaying.showLevel(SystemLevel(kind: .brightness, value: SystemControls.adjustBrightness(by: -step)))
        }
    }

    private func promptForKey(_ provider: DeclarativeWeatherProvider) -> String? {
        let alert = NSAlert()
        alert.messageText = "API key for \(provider.name)"
        alert.informativeText = "Stored in your Keychain and sent only to this provider."
        let field = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        alert.accessoryView = field
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn, !field.stringValue.isEmpty else { return nil }
        return field.stringValue
    }
}
