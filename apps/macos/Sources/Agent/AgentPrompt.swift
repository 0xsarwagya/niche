import Foundation

/// A question posted by an external agent, shown in the notch for the user to answer.
struct AgentPrompt: Equatable, Sendable, Identifiable {
    let id: String
    let question: String
}
