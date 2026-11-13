import SwiftUI

/// How expressive the notch's motion is. `system` follows macOS Reduce Motion.
enum MotionLevel: String, CaseIterable, Sendable {
    case system
    case reduced
    case expressive
}

/// Niche's motion vocabulary — four primitives, each with its own personality and each
/// tightening when motion is reduced:
/// - **expand**: the shell physically grows (hover, agent arrival, media expansion).
/// - **morph**: one kind of content becomes another without the shell collapsing.
/// - **pulse**: the shell holds still while something inside reacts (volume, battery).
/// - **dismiss**: leaves a touch faster than it arrived, without a visible spring-back.
enum NicheMotion {
    static func isReduced(_ level: MotionLevel, system: Bool) -> Bool {
        switch level {
        case .reduced: true
        case .expressive: false
        case .system: system
        }
    }

    static func expand(reduced: Bool) -> Animation {
        reduced ? .easeOut(duration: 0.18) : .spring(response: 0.30, dampingFraction: 0.82)
    }

    static func morph(reduced: Bool) -> Animation {
        reduced ? .easeInOut(duration: 0.14) : .spring(response: 0.26, dampingFraction: 0.88)
    }

    static func pulse(reduced: Bool) -> Animation {
        reduced ? .easeOut(duration: 0.12) : .spring(response: 0.18, dampingFraction: 0.72)
    }

    static func dismiss(reduced: Bool) -> Animation {
        .easeIn(duration: reduced ? 0.12 : 0.18)
    }
}
