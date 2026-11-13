import SwiftUI

/// The island silhouette. Its top edge is flush to the screen's ceiling at full width, then sweeps
/// inward through concave "shoulders" to a slightly narrower body with convex bottom corners. The
/// shoulders make the black read as hanging out of the notch rather than a rectangle pinned near
/// the top. Both radii animate, so the shell morphs elastically between states.
struct NotchShape: Shape {
    var bottomRadius: CGFloat
    var shoulderRadius: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(bottomRadius, shoulderRadius) }
        set {
            bottomRadius = newValue.first
            shoulderRadius = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let s = max(0, min(shoulderRadius, w / 2, h))
        let b = max(0, min(bottomRadius, w / 2 - s, h - s))
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        if s > 0 {
            path.addQuadCurve(to: CGPoint(x: s, y: s), control: CGPoint(x: s, y: 0))
        }
        path.addLine(to: CGPoint(x: s, y: h - b))
        if b > 0 {
            path.addQuadCurve(to: CGPoint(x: s + b, y: h), control: CGPoint(x: s, y: h))
        }
        path.addLine(to: CGPoint(x: w - s - b, y: h))
        if b > 0 {
            path.addQuadCurve(to: CGPoint(x: w - s, y: h - b), control: CGPoint(x: w - s, y: h))
        }
        path.addLine(to: CGPoint(x: w - s, y: s))
        if s > 0 {
            path.addQuadCurve(to: CGPoint(x: w, y: 0), control: CGPoint(x: w - s, y: 0))
        }
        path.closeSubpath()
        return path
    }
}
