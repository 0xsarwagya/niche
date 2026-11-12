import ServiceManagement
import os

/// Registers Niche as a login item via SMAppService.
enum LoginItem {
    private static let logger = Logger(subsystem: "com.niche.app", category: "LoginItem")

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func toggle() {
        do {
            if isEnabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            logger.error("login item toggle failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
