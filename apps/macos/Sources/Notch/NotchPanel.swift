import AppKit
import SwiftUI
import os

/// Hosting view that only accepts clicks within the island's current rect, so the
/// clear margins of the panel stay click-through.
private final class PassthroughHostingView: NSHostingView<NotchView> {
    private let model: NowPlayingModel
    private let weather: WeatherModel
    private let notch: NotchMetrics
    var contextMenu: NSMenu?

    init(model: NowPlayingModel, weather: WeatherModel, notch: NotchMetrics) {
        self.model = model
        self.weather = weather
        self.notch = notch
        super.init(rootView: NotchView(model: model, weather: weather, notch: notch))
    }

    @MainActor required init(rootView: NotchView) {
        fatalError("use init(model:weather:notch:)")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let local = convert(point, from: superview)
        let content = NotchView.resolveContent(model: model, weather: weather)
        let size = NotchGeometry.islandSize(content: content, hovered: model.isHovered, notch: notch)
        let islandRect = CGRect(
            x: (bounds.width - size.width) / 2,
            y: isFlipped ? 0 : bounds.height - size.height,
            width: size.width,
            height: size.height
        )
        return islandRect.contains(local) ? super.hitTest(point) : nil
    }

    /// Take keyboard focus only when the user clicks an active prompt — never on arrival, so an
    /// agent's question can't steal the keyboard while the user works elsewhere.
    override func mouseDown(with event: NSEvent) {
        if model.prompt != nil {
            window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
        super.mouseDown(with: event)
    }

    /// Right-click the notch for quick actions. Only reaches here over the island, since hitTest
    /// rejects the clear margins.
    override func rightMouseDown(with event: NSEvent) {
        guard let contextMenu else { return super.rightMouseDown(with: event) }
        NSMenu.popUpContextMenu(contextMenu, with: event, for: self)
    }

    /// Scroll over the notch to nudge the volume, reusing the HUD surface. Gated on the HUD module
    /// so disabling it also releases the scroll gesture. Momentum coast is ignored so one swipe
    /// doesn't overshoot, and the trackpad's fine deltas are damped harder than a wheel's clicks.
    override func scrollWheel(with event: NSEvent) {
        guard Preferences.shared.showHUD, event.momentumPhase == [], event.scrollingDeltaY != 0 else {
            return super.scrollWheel(with: event)
        }
        let gain = event.hasPreciseScrollingDeltas ? 0.002 : 0.04
        let step = max(-0.08, min(0.08, event.scrollingDeltaY * gain))
        model.showLevel(SystemLevel(kind: .volume, value: SystemControls.adjustVolume(by: step)))
    }
}

/// Borderless, non-activating panel pinned at the notch across every Space.
final class NotchPanel: NSPanel {
    private static let logger = Logger(subsystem: "com.niche.app", category: "NotchPanel")
    private let hosting: PassthroughHostingView

    override var canBecomeKey: Bool { true }

    init(screen: NSScreen, model: NowPlayingModel, weather: WeatherModel) {
        let notch = NotchMetrics(screen: screen)
        let frame = NotchGeometry.panelFrame(in: screen.frame)
        hosting = PassthroughHostingView(model: model, weather: weather, notch: notch)
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

        hosting.sizingOptions = []
        hosting.autoresizingMask = [.width, .height]
        contentView = hosting
        setFrame(frame, display: true)
        Self.logger.info("Notch panel created")
    }

    /// Supplies the quick-action menu shown when the notch is right-clicked.
    func setContextMenu(_ menu: NSMenu) {
        hosting.contextMenu = menu
    }
}
