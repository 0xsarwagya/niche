import AppKit

/// The notch footprint the island wraps. Real on notched Macs, a fake notch elsewhere.
struct NotchMetrics: Equatable {
    var width: CGFloat
    var height: CGFloat

    static let fake = NotchMetrics(width: 200, height: 32)

    @MainActor
    init(screen: NSScreen) {
        let top = screen.safeAreaInsets.top
        guard top > 0 else {
            self = .fake
            return
        }
        height = top
        if let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea {
            width = screen.frame.width - left.width - right.width
        } else {
            width = NotchMetrics.fake.width
        }
    }

    init(width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
    }
}
