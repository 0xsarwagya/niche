import AppKit
import CoreGraphics
import os

/// A system media key we handle.
enum MediaKey: Equatable, Sendable {
    case volumeUp
    case volumeDown
    case mute
    case brightnessUp
    case brightnessDown

    /// Maps an NX_KEYTYPE_* code (from IOKit's ev_keymap) to a handled key.
    static func forKeyCode(_ code: Int) -> MediaKey? {
        switch code {
        case 0: .volumeUp
        case 1: .volumeDown
        case 2: .brightnessUp
        case 3: .brightnessDown
        case 7: .mute
        default: nil
        }
    }
}

/// Taps the system-defined media keys and consumes volume/brightness so macOS never draws its OSD.
/// Requires Accessibility permission; without it the tap won't install and the system OSD remains.
/// Consumed keys are published on `keys` for a main-actor consumer to act on.
final class MediaKeyTap {
    private static let logger = Logger(subsystem: "com.niche.app", category: "MediaKeyTap")

    let keys: AsyncStream<MediaKey>
    private let continuation: AsyncStream<MediaKey>.Continuation
    private var tap: CFMachPort?

    init() {
        (keys, continuation) = AsyncStream<MediaKey>.makeStream()
    }

    @MainActor
    func start() -> Bool {
        let callback: CGEventTapCallBack = { _, _, event, userInfo in
            guard let userInfo else { return Unmanaged.passUnretained(event) }
            return Unmanaged<MediaKeyTap>.fromOpaque(userInfo).takeUnretainedValue().process(event)
        }
        guard let port = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(1 << 14),
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            Self.logger.info("media-key tap not created; Accessibility likely not granted")
            return false
        }
        tap = port
        let source = CFMachPortCreateRunLoopSource(nil, port, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: port, enable: true)
        return true
    }

    private func process(_ event: CGEvent) -> Unmanaged<CGEvent>? {
        let passthrough = Unmanaged.passUnretained(event)
        guard let nsEvent = NSEvent(cgEvent: event), nsEvent.subtype.rawValue == 8 else {
            return passthrough
        }
        let keyCode = Int((nsEvent.data1 & 0xFFFF_0000) >> 16)
        guard let key = MediaKey.forKeyCode(keyCode) else { return passthrough }
        if ((nsEvent.data1 & 0x0000_FF00) >> 8) == 0x0A {
            continuation.yield(key)
        }
        return nil
    }
}
