import AppKit
import SwiftUI
import os

/// Hosting view that only accepts clicks within the island's current rect, so the
/// clear margins of the panel stay click-through.
private final class PassthroughHostingView: NSHostingView<NotchView> {
    private let model: NowPlayingModel

    init(model: NowPlayingModel) {
        self.model = model
        super.init(rootView: NotchView(model: model))
    }

    @MainActor required init(rootView: NotchView) {
        fatalError("use init(model:)")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let local = convert(point, from: superview)
        let size = NotchGeometry.islandSize(hasTrack: model.current != nil, hovered: model.isHovered)
        let islandRect = CGRect(
            x: (bounds.width - size.width) / 2,
            y: isFlipped ? 0 : bounds.height - size.height,
            width: size.width,
            height: size.height
        )
        return islandRect.contains(local) ? super.hitTest(point) : nil
    }
}

/// Borderless, non-activating panel pinned at the notch across every Space.
final class NotchPanel: NSPanel {
    private static let logger = Logger(subsystem: "com.niche.app", category: "NotchPanel")

    init(screen: NSScreen, model: NowPlayingModel) {
        let frame = NotchGeometry.panelFrame(in: screen.frame, topInset: screen.safeAreaInsets.top)
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

        let hosting = PassthroughHostingView(model: model)
        hosting.sizingOptions = []
        hosting.autoresizingMask = [.width, .height]
        contentView = hosting
        setFrame(frame, display: true)
        Self.logger.info("Notch panel created")
    }
}
