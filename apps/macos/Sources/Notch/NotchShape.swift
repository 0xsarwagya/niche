import SwiftUI

/// The island silhouette: a flat top that melts into the notch line with concave
/// top corners, and a deeply rounded bottom — so it reads as the notch growing a
/// panel rather than a card floating below it. The top corners overhang by
/// `topCornerRadius`, so give the island horizontal margin inside its stage.
struct NotchShape: Shape {
    var topCornerRadius: CGFloat = 10
    var bottomCornerRadius: CGFloat = 20

    func path(in rect: CGRect) -> Path {
        let topR = min(topCornerRadius, rect.height / 2)
        let bottomR = min(bottomCornerRadius, rect.height / 2)

        var path = Path()
        path.move(to: CGPoint(x: rect.minX - topR, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.minY + topR),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - bottomR))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + bottomR, y: rect.maxY),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.maxX - bottomR, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY - bottomR),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + topR))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX + topR, y: rect.minY),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        path.closeSubpath()
        return path
    }
}
