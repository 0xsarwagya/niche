import Foundation

/// A question posted by an external agent, shown in the notch for the user to answer.
/// With `options`, the notch shows tappable choices; otherwise a free-text reply field.
struct AgentPrompt: Equatable, Sendable, Identifiable {
    let id: String
    let question: String
    var options: [String] = []
}
