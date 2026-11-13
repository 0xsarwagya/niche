import Foundation
import Testing
@testable import Niche

struct PromptInboxTests {
    private func tempDir() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("niche-inbox-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test func readsAskFileAsPrompt() throws {
        let dir = tempDir()
        try "Deploy to prod?\n".write(to: dir.appendingPathComponent("abc.ask"), atomically: true, encoding: .utf8)
        #expect(PromptInbox.pending(in: dir) == [AgentPrompt(id: "abc", question: "Deploy to prod?")])
    }

    @Test func readsJsonAskWithOptions() throws {
        let json = #"{"question":"Deploy?","options":["Yes","No"]}"#
        #expect(PromptInbox.prompt(from: Data(json.utf8), id: "x")
            == AgentPrompt(id: "x", question: "Deploy?", options: ["Yes", "No"]))
    }

    @Test func plainTextHasNoOptions() {
        #expect(PromptInbox.prompt(from: Data("Hi?".utf8), id: "x")?.options.isEmpty == true)
    }

    @Test func consumesAskFile() throws {
        let dir = tempDir()
        let ask = dir.appendingPathComponent("abc.ask")
        try "Hi?".write(to: ask, atomically: true, encoding: .utf8)
        _ = PromptInbox.pending(in: dir)
        #expect(!FileManager.default.fileExists(atPath: ask.path))
    }

    @Test func ignoresNonAskFiles() throws {
        let dir = tempDir()
        try "x".write(to: dir.appendingPathComponent("note.txt"), atomically: true, encoding: .utf8)
        #expect(PromptInbox.pending(in: dir).isEmpty)
    }

    @Test func answerWritesReply() throws {
        let dir = tempDir()
        PromptInbox(directory: dir).answer(id: "abc", text: "yes")
        let reply = try String(contentsOf: dir.appendingPathComponent("abc.reply"), encoding: .utf8)
        #expect(reply == "yes")
    }
}
