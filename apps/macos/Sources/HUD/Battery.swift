import Foundation
import IOKit.ps

/// Emits a battery HUD level on plug-in, unplug, and when the battery goes low.
// ponytail: 2s poll of IOKit power sources; swap for IOPSNotificationCreateRunLoopSource if needed.
struct BatteryMonitor: SystemLevelsSource {
    var updates: AsyncStream<SystemLevel> {
        AsyncStream { continuation in
            let task = Task {
                var lastCharging: Bool?
                var wasLow = false
                while !Task.isCancelled {
                    if let snapshot = Battery.read() {
                        if let previous = lastCharging, previous != snapshot.charging {
                            continuation.yield(snapshot.level)
                        }
                        let low = Battery.isLow(percent: snapshot.percent, charging: snapshot.charging)
                        if low, !wasLow {
                            continuation.yield(snapshot.lowLevel)
                        }
                        lastCharging = snapshot.charging
                        wasLow = low
                    }
                    try? await Task.sleep(for: .seconds(2))
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

/// Reads the Mac battery via IOKit power sources.
enum Battery {
    struct Snapshot {
        let percent: Int
        let charging: Bool

        var level: SystemLevel {
            SystemLevel(kind: .battery, value: Double(percent) / 100, charging: charging)
        }

        var lowLevel: SystemLevel {
            SystemLevel(kind: .battery, value: Double(percent) / 100, charging: false, warning: true)
        }
    }

    static func isLow(percent: Int, charging: Bool) -> Bool {
        !charging && percent <= 20
    }

    static func read() -> Snapshot? {
        let blob = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        guard let sources = IOPSCopyPowerSourcesList(blob).takeRetainedValue() as? [CFTypeRef] else {
            return nil
        }
        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(blob, source).takeUnretainedValue() as? [String: Any],
                  let capacity = description[kIOPSCurrentCapacityKey] as? Int else {
                continue
            }
            let charging = (description[kIOPSIsChargingKey] as? Bool) ?? false
            return Snapshot(percent: capacity, charging: charging)
        }
        return nil
    }
}
