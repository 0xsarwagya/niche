import Foundation
import Security

/// Minimal Keychain wrapper for weather-adapter API keys, one per provider id.
/// Keys live here only — never in the adapter JSON, UserDefaults, or logs.
enum Keychain {
    private static let service = "com.niche.weather"

    static func key(for providerID: String) -> String? {
        var query = baseQuery(for: providerID)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    static func setKey(_ value: String, for providerID: String) {
        SecItemDelete(baseQuery(for: providerID) as CFDictionary)
        var item = baseQuery(for: providerID)
        item[kSecValueData as String] = Data(value.utf8)
        SecItemAdd(item as CFDictionary, nil)
    }

    static func removeKey(for providerID: String) {
        SecItemDelete(baseQuery(for: providerID) as CFDictionary)
    }

    private static func baseQuery(for providerID: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: providerID,
        ]
    }
}
