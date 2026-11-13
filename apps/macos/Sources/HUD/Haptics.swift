import AppKit

/// Subtle trackpad haptics for the notch's key interactions (no-op without a haptic trackpad).
@MainActor
enum Haptics {
    static func tap() {
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
    }

    static func expand() {
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
    }
}
