import Foundation

/// A transient agent state shown in the notch — no reply expected. `thinking` persists until
/// replaced or cleared; `success`/`failure` auto-dismiss; `clear` removes the current status.
struct AgentStatus: Equatable, Sendable, Identifiable {
    enum State: String, Sendable {
        case thinking
        case success
        case failure
        case clear
    }

    let id: String
    let state: State
    let text: String
}
