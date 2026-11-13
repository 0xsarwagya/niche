import CoreGraphics

/// Pure placement math for the notch panel; no AppKit so it stays testable.
/// The panel is a clear top-anchored stage; the SwiftUI island wraps the notch inside it.
enum NotchGeometry {
    /// What the island is currently showing, in priority order.
    enum Content {
        case hidden
        case prompt
        case hud
        case timer
        case nowPlaying
        case weather
    }

    static let stageSize = CGSize(width: 440, height: 150)

    static func panelFrame(in screen: CGRect, size: CGSize = stageSize) -> CGRect {
        let originX = screen.minX + (screen.width - size.width) / 2
        let originY = screen.maxY - size.height
        return CGRect(x: originX, y: originY, width: size.width, height: size.height)
    }

    /// Resolves what the island shows; a pending question wins, then a transient HUD, a timer, media.
    static func content(prompt: Bool, hasTrack: Bool, hud: Bool, timer: Bool, weather: Bool) -> Content {
        if prompt { return .prompt }
        if hud { return .hud }
        if timer { return .timer }
        if hasTrack { return .nowPlaying }
        if weather { return .weather }
        return .hidden
    }

    /// Island size for the current content, including the notch footprint at the top.
    /// The single source of truth for the SwiftUI frame and the panel's hit region.
    static func islandSize(content: Content, hovered: Bool, notch: NotchMetrics) -> CGSize {
        switch content {
        case .hidden:
            return CGSize(width: notch.width, height: notch.height)
        case .prompt:
            return CGSize(width: max(380, notch.width + 170), height: notch.height + 92)
        case .hud, .timer, .weather:
            return CGSize(width: max(300, notch.width + 100), height: notch.height + 44)
        case .nowPlaying:
            let width: CGFloat = hovered ? max(384, notch.width + 190) : max(300, notch.width + 100)
            let contentHeight: CGFloat = hovered ? 82 : 48
            return CGSize(width: width, height: notch.height + contentHeight)
        }
    }
}
