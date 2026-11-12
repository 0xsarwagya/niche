import CoreAudio
import CoreGraphics
import Foundation
import os

/// Polls output volume and display brightness and emits the ones that change.
// ponytail: 200ms poll, not event-driven; swap for a CoreAudio listener + key events if CPU matters.
struct SystemLevelsPoller: SystemLevelsSource {
    var updates: AsyncStream<SystemLevel> {
        AsyncStream { continuation in
            let task = Task {
                var lastVolume: Double?
                var lastBrightness: Double?
                var primed = false
                while !Task.isCancelled {
                    let volume = SystemLevels.outputVolume()
                    let brightness = SystemLevels.displayBrightness()
                    if primed {
                        if let volume, SystemLevels.changed(lastVolume, volume) {
                            continuation.yield(SystemLevel(kind: .volume, value: volume))
                        }
                        if let brightness, SystemLevels.changed(lastBrightness, brightness) {
                            continuation.yield(SystemLevel(kind: .brightness, value: brightness))
                        }
                    }
                    if let volume { lastVolume = volume }
                    if let brightness { lastBrightness = brightness }
                    primed = true
                    try? await Task.sleep(for: .milliseconds(200))
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

/// Reads output volume (CoreAudio) and display brightness (DisplayServices SPI).
enum SystemLevels {
    private static let logger = Logger(subsystem: "com.niche.app", category: "SystemLevels")

    /// True when `current` differs from a known `previous` by more than `epsilon`.
    static func changed(_ previous: Double?, _ current: Double, epsilon: Double = 0.005) -> Bool {
        guard let previous else { return false }
        return abs(current - previous) > epsilon
    }

    static func outputVolume() -> Double? {
        var deviceID = AudioObjectID(0)
        var deviceSize = UInt32(MemoryLayout<AudioObjectID>.size)
        var deviceAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &deviceAddress, 0, nil, &deviceSize, &deviceID
        ) == noErr else {
            return nil
        }

        var volume = Float32(0)
        var volumeSize = UInt32(MemoryLayout<Float32>.size)
        var volumeAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        guard AudioObjectGetPropertyData(deviceID, &volumeAddress, 0, nil, &volumeSize, &volume) == noErr else {
            return nil
        }
        return Double(volume)
    }

    static func displayBrightness() -> Double? {
        guard let getBrightness else { return nil }
        var value: Float = 0
        guard getBrightness(CGMainDisplayID(), &value) == 0 else { return nil }
        return Double(value)
    }

    private typealias GetBrightness = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32

    nonisolated(unsafe) private static let getBrightness: GetBrightness? = {
        let path = "/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices"
        guard let handle = dlopen(path, RTLD_NOW), let symbol = dlsym(handle, "DisplayServicesGetBrightness") else {
            logger.warning("DisplayServices brightness SPI unavailable")
            return nil
        }
        return unsafeBitCast(symbol, to: GetBrightness.self)
    }()
}
