import Testing
@testable import Niche

struct BatteryTests {
    @Test func lowWhenBelowThresholdAndNotCharging() {
        #expect(Battery.isLow(percent: 18, charging: false) == true)
    }

    @Test func notLowWhileCharging() {
        #expect(Battery.isLow(percent: 10, charging: true) == false)
    }

    @Test func notLowWhenAmpleCharge() {
        #expect(Battery.isLow(percent: 80, charging: false) == false)
    }
}
