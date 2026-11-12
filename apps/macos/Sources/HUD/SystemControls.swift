import CoreAudio
import CoreGraphics
import Foundation

/// Applies the volume/brightness change ourselves after the media-key tap consumes the key
/// (so the system OSD never shows). Returns the new 0...1 level for the HUD.
enum SystemControls {
    static func adjustVolume(by step: Double) -> Double {
        let next = min(1, max(0, (SystemLevels.outputVolume() ?? 0) + step))
        setVolume(Float(next))
        return next
    }

    static func toggleMute() -> Double {
        let muted = !currentMute()
        setMute(muted)
        return muted ? 0 : (SystemLevels.outputVolume() ?? 0)
    }

    static func adjustBrightness(by step: Double) -> Double {
        let next = min(1, max(0, (SystemLevels.displayBrightness() ?? 0) + step))
        setBrightness?(CGMainDisplayID(), Float(next))
        return next
    }

    private static func setVolume(_ value: Float) {
        guard let device = SystemLevels.defaultOutputDevice() else { return }
        var volume = value
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectSetPropertyData(device, &address, 0, nil, UInt32(MemoryLayout<Float32>.size), &volume)
    }

    private static func currentMute() -> Bool {
        guard let device = SystemLevels.defaultOutputDevice() else { return false }
        var muted = UInt32(0)
        var size = UInt32(MemoryLayout<UInt32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectGetPropertyData(device, &address, 0, nil, &size, &muted)
        return muted == 1
    }

    private static func setMute(_ muted: Bool) {
        guard let device = SystemLevels.defaultOutputDevice() else { return }
        var value = UInt32(muted ? 1 : 0)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectSetPropertyData(device, &address, 0, nil, UInt32(MemoryLayout<UInt32>.size), &value)
    }

    private typealias SetBrightness = @convention(c) (CGDirectDisplayID, Float) -> Int32

    nonisolated(unsafe) private static let setBrightness: SetBrightness? = {
        let path = "/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices"
        guard let handle = dlopen(path, RTLD_NOW), let symbol = dlsym(handle, "DisplayServicesSetBrightness") else {
            return nil
        }
        return unsafeBitCast(symbol, to: SetBrightness.self)
    }()
}
