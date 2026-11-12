import AppKit
import os

/// Creates the notch panel on launch and owns it for the app's lifetime.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let logger = Logger(subsystem: "com.niche.app", category: "AppDelegate")
    private var panel: NotchPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let screen = NSScreen.main else {
            Self.logger.error("No main screen; cannot place the notch panel")
            return
        }
        let panel = NotchPanel(screen: screen)
        panel.orderFrontRegardless()
        self.panel = panel
        Self.logger.info("Niche launched")
    }
}
