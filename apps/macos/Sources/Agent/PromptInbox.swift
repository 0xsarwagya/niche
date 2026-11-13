import Foundation

/// One thing an agent dropped in the inbox: a question needing a reply, or a transient status.
enum InboxItem: Equatable, Sendable {
    case prompt(AgentPrompt)
    case status(AgentStatus)
}

/// A file-based inbox so any agent can talk to the user through the notch.
///
/// `<id>.ask` posts a question (UTF-8 text, or JSON `{"question","options"}`); the notch shows it
/// and writes the answer to `<id>.reply`. `<id>.status` posts a transient state
/// (`{"state","text"}`) with no reply. No server, just files.
struct PromptInbox: Sendable {
    let directory: URL

    init(directory: URL = PromptInbox.defaultDirectory) {
        self.directory = directory
    }

    static var defaultDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Niche/inbox", isDirectory: true)
    }

    /// Polls for new `.ask` / `.status` files. Polling, not FSEvents: the inbox is tiny and idle
    /// most of the time.
    var items: AsyncStream<InboxItem> {
        AsyncStream { continuation in
            let directory = directory
            let task = Task {
                try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                while !Task.isCancelled {
                    for item in PromptInbox.pending(in: directory) {
                        continuation.yield(item)
                    }
                    try? await Task.sleep(for: .milliseconds(500))
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Reads and consumes every `.ask` / `.status` file, oldest first.
    static func pending(in directory: URL) -> [InboxItem] {
        let keys: [URLResourceKey] = [.contentModificationDateKey]
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: keys
        ) else {
            return []
        }
        return files
            .filter { $0.pathExtension == "ask" || $0.pathExtension == "status" }
            .sorted { modified($0) < modified($1) }
            .compactMap { file in
                guard let data = try? Data(contentsOf: file) else { return nil }
                try? FileManager.default.removeItem(at: file)
                let id = file.deletingPathExtension().lastPathComponent
                if file.pathExtension == "status" {
                    return status(from: data, id: id).map(InboxItem.status)
                }
                return prompt(from: data, id: id).map(InboxItem.prompt)
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

    /// A `.status` file is JSON `{"state": "thinking|success|failure|clear", "text"?}`.
    static func status(from data: Data, id: String) -> AgentStatus? {
        guard let payload = try? JSONDecoder().decode(StatusPayload.self, from: data),
              let state = AgentStatus.State(rawValue: payload.state) else {
            return nil
        }
        let text = (payload.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return AgentStatus(id: id, state: state, text: text)
    }

    private struct Payload: Decodable {
        let question: String
        let options: [String]?
    }

    private struct StatusPayload: Decodable {
        let state: String
        let text: String?
    }

    func answer(id: String, text: String) {
        let url = directory.appendingPathComponent("\(id).reply")
        try? Data(text.utf8).write(to: url)
    }

    private static func modified(_ url: URL) -> Date {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
    }
}
