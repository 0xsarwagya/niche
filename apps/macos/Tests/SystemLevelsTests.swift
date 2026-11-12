import Testing
@testable import Niche

struct SystemLevelsTests {
    @Test func firstReadingIsNotAChange() {
        #expect(SystemLevels.changed(nil, 0.5) == false)
    }

    @Test func largeDeltaIsAChange() {
        #expect(SystemLevels.changed(0.5, 0.7) == true)
    }

    @Test func tinyDeltaIsIgnored() {
        #expect(SystemLevels.changed(0.5, 0.5001) == false)
    }
}
