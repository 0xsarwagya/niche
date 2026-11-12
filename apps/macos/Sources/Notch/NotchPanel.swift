import AppKit
import SwiftUI
import os

/// Borderless, non-activating panel pinned at the notch across every Space.
final class NotchPanel: NSPanel {
    private static let logger = Logger(subsystem: "com.niche.app", category: "NotchPanel")

    init(screen: NSScreen, model: NowPlayingModel) {
        let frame = NotchGeometry.panelFrame(in: screen.frame)
        super.init(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovable = false
        hidesOnDeactivate = false
        ignoresMouseEvents = true

        let hosting = NSHostingView(rootView: NotchRoot(model: model))
        hosting.sizingOptions = []
        hosting.autoresizingMask = [.width, .height]
        contentView = hosting
        setFrame(frame, display: true)
        Self.logger.info("Notch panel created")
    }
}
