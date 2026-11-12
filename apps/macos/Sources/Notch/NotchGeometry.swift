import CoreGraphics

/// Pure placement math for the notch panel; no AppKit so it stays testable.
/// The panel is a clear top-centered stage; the SwiftUI island sizes itself inside it.
enum NotchGeometry {
    static let defaultSize = CGSize(width: 420, height: 90)

    /// Frame centered horizontally against the top edge of `screen`, in screen coordinates.
    static func panelFrame(in screen: CGRect, size: CGSize = defaultSize) -> CGRect {
        let originX = screen.minX + (screen.width - size.width) / 2
        let originY = screen.maxY - size.height
        return CGRect(x: originX, y: originY, width: size.width, height: size.height)
    }

    /// Size of the black island for the current state; the single source of truth for both
    /// the SwiftUI frame and the panel's interactive hit region.
    static func islandSize(hasTrack: Bool, hovered: Bool) -> CGSize {
        guard hasTrack else { return CGSize(width: 200, height: 32) }
        return hovered ? CGSize(width: 384, height: 64) : CGSize(width: 300, height: 46)
    }
}
