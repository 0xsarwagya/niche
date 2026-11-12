import CoreGraphics

/// Pure placement math for the notch panel; no AppKit so it stays testable.
enum NotchGeometry {
    static let defaultSize = CGSize(width: 220, height: 32)

    /// Frame centered horizontally against the top edge of `screen`, in screen coordinates.
    static func panelFrame(in screen: CGRect, size: CGSize = defaultSize) -> CGRect {
        let originX = screen.minX + (screen.width - size.width) / 2
        let originY = screen.maxY - size.height
        return CGRect(x: originX, y: originY, width: size.width, height: size.height)
    }
}
