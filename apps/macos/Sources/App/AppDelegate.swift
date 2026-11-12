import AppKit
import os

/// Creates the notch panel on launch and feeds it now-playing state.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let logger = Logger(subsystem: "com.niche.app", category: "AppDelegate")
    private let nowPlaying = NowPlayingModel(
        controller: MediaRemoteController(),
        artworkSource: MediaRemoteArtworkSource()
    )
    private var panel: NotchPanel?

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
        Self.logger.info("Niche launched")
    }

    func applicationWillTerminate(_ notification: Notification) {
        nowPlaying.stop()
    }
}
