import Testing
@testable import Niche

struct NicheMotionTests {
    @Test func systemFollowsTheOS() {
        #expect(NicheMotion.isReduced(.system, system: true))
    }

    @Test func reducedAlwaysReduces() {
        #expect(NicheMotion.isReduced(.reduced, system: false))
    }

    @Test func expressiveNeverReduces() {
        #expect(!NicheMotion.isReduced(.expressive, system: true))
    }
}
