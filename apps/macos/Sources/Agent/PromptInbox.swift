import Foundation

/// A file-based inbox so any agent can ask the user a question through the notch.
///
/// An agent drops `<id>.ask` (UTF-8 question) into the inbox directory; the notch shows it
/// and writes the answer to `<id>.reply`. Plain text both ways — no server, no JSON.
struct PromptInbox: Sendable {
    let directory: URL

    init(directory: URL = PromptInbox.defaultDirectory) {
        self.directory = directory
    }

    static var defaultDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Niche/inbox", isDirectory: true)
    }

    /// Polls for new `.ask` files. Polling, not FSEvents: the inbox is tiny and idle most of the time.
    var prompts: AsyncStream<AgentPrompt> {
        AsyncStream { continuation in
            let directory = directory
            let task = Task {
                try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                while !Task.isCancelled {
                    for prompt in PromptInbox.pending(in: directory) {
                        continuation.yield(prompt)
                    }
                    try? await Task.sleep(for: .milliseconds(500))
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Reads and consumes every `.ask` file, oldest first.
    static func pending(in directory: URL) -> [AgentPrompt] {
        let keys: [URLResourceKey] = [.contentModificationDateKey]
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: keys
        ) else {
            return []
        }
        return files
            .filter { $0.pathExtension == "ask" }
            .sorted { modified($0) < modified($1) }
            .compactMap { file in
                guard let data = try? Data(contentsOf: file) else { return nil }
                try? FileManager.default.removeItem(at: file)
                return prompt(from: data, id: file.deletingPathExtension().lastPathComponent)
            }
    }

    /// A `.ask` file is JSON `{"question", "options"?}` for tappable choices, or plain text
    /// for a free-text question.
    static func prompt(from data: Data, id: String) -> AgentPrompt? {
        if let payload = try? JSONDecoder().decode(Payload.self, from: data) {
            let question = payload.question.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !question.isEmpty else { return nil }
            return AgentPrompt(id: id, question: question, options: payload.options ?? [])
        }
        let question = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        return question.isEmpty ? nil : AgentPrompt(id: id, question: question)
    }

    private struct Payload: Decodable {
        let question: String
        let options: [String]?
    }

    func answer(id: String, text: String) {
        let url = directory.appendingPathComponent("\(id).reply")
        try? Data(text.utf8).write(to: url)
    }

    private static func modified(_ url: URL) -> Date {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
    }
}
