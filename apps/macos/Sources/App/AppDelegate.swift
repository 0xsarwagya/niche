import AppKit
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
        Self.logger.info("Niche launched")
    }

    func applicationWillTerminate(_ notification: Notification) {
        nowPlaying.stop()
        weather.stop()
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
