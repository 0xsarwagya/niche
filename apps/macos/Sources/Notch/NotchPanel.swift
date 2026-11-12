import AppKit
import SwiftUI
import os

/// Hosting view that only accepts clicks within the island's current rect, so the
/// clear margins of the panel stay click-through.
private final class PassthroughHostingView: NSHostingView<NotchView> {
    private let model: NowPlayingModel
    private let weather: WeatherModel
    private let notch: NotchMetrics

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
        let content = NotchGeometry.content(
            hasTrack: model.current != nil,
            hud: model.hud != nil,
            timer: model.timerRemaining != nil,
            weather: model.isHovered && weather.snapshot != nil
        )
        let size = NotchGeometry.islandSize(content: content, hovered: model.isHovered, notch: notch)
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

    init(screen: NSScreen, model: NowPlayingModel, weather: WeatherModel) {
        let notch = NotchMetrics(screen: screen)
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

        let hosting = PassthroughHostingView(model: model, weather: weather, notch: notch)
        hosting.sizingOptions = []
        hosting.autoresizingMask = [.width, .height]
        contentView = hosting
        setFrame(frame, display: true)
        Self.logger.info("Notch panel created")
    }
}
