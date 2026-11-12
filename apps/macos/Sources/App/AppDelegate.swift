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
        let panel = NotchPanel(screen: screen, model: nowPlaying)
        panel.orderFrontRegardless()
        self.panel = panel
        setUpMenuBar()
        Self.logger.info("Niche launched")
    }

    func applicationWillTerminate(_ notification: Notification) {
        nowPlaying.stop()
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
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Niche", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        item.menu = menu
        statusItem = item
    }

    @objc private func startTimer(_ sender: NSMenuItem) {
        nowPlaying.startTimer(TimeInterval(sender.tag * 60))
    }
}
