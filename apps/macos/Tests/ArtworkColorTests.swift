import AppKit
import Testing
@testable import Niche

struct ArtworkColorTests {
    @Test func picksVividRedOverMostlyBlack() {
        var pixels: [UInt8] = []
        for _ in 0..<90 { pixels += [0, 0, 0, 255] }
        for _ in 0..<10 { pixels += [230, 20, 20, 255] }
        let color = ArtworkColor.dominantVivid(in: pixels)!.usingColorSpace(.deviceRGB)!
        #expect(color.redComponent > color.greenComponent && color.redComponent > color.blueComponent)
    }

    @Test func fallsBackWhenNothingVivid() {
        let pixels = [UInt8](repeating: 128, count: 40)
        #expect(ArtworkColor.dominantVivid(in: pixels) != nil)
    }
}
