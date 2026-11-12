import CoreGraphics
import Testing
@testable import Niche

struct NotchGeometryTests {
    @Test func panelIsCenteredAtTopEdge() {
        let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let frame = NotchGeometry.panelFrame(in: screen, size: CGSize(width: 200, height: 30))
        #expect(frame == CGRect(x: 620, y: 870, width: 200, height: 30))
    }
}
