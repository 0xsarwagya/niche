import CoreGraphics

/// Pure placement math for the notch panel; no AppKit so it stays testable.
/// The panel is a clear top-anchored stage; the SwiftUI island wraps the notch inside it.
enum NotchGeometry {
    static let stageSize = CGSize(width: 440, height: 150)

    /// Frame centered horizontally against the top edge of `screen`, in screen coordinates.
    static func panelFrame(in screen: CGRect, size: CGSize = stageSize) -> CGRect {
        let originX = screen.minX + (screen.width - size.width) / 2
        let originY = screen.maxY - size.height
        return CGRect(x: originX, y: originY, width: size.width, height: size.height)
    }

    /// Island size for the current state, including the notch footprint at the top.
    /// The single source of truth for the SwiftUI frame and the panel's hit region.
    static func islandSize(hasTrack: Bool, hovered: Bool, hud: Bool, notch: NotchMetrics) -> CGSize {
        if hud { return CGSize(width: max(300, notch.width + 100), height: notch.height + 42) }
        guard hasTrack else { return CGSize(width: notch.width, height: notch.height) }
        let width: CGFloat = hovered ? max(384, notch.width + 190) : max(300, notch.width + 100)
        let contentHeight: CGFloat = hovered ? 82 : 48
        return CGSize(width: width, height: notch.height + contentHeight)
    }
}
