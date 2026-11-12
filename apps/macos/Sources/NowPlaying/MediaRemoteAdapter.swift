import Foundation

/// Locates the vendored mediaremote-adapter bundled in the app's Resources.
enum MediaRemoteAdapter {
    static func paths() -> (script: URL, framework: URL)? {
        guard let resources = Bundle.main.resourceURL else { return nil }
        let base = resources.appending(path: "mediaremote-adapter")
        let script = base.appending(path: "mediaremote-adapter.pl")
        let framework = base.appending(path: "MediaRemoteAdapter.framework")
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: script.path),
              fileManager.fileExists(atPath: framework.path) else { return nil }
        return (script, framework)
    }
}
