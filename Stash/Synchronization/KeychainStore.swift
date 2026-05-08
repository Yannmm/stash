//
//  KeychainStore.swift
//  Stash
//
//  Created by Cursor on 2026/4/13.
//

import Foundation
import Security

final class KeychainStore {
    private let service: String

    init(service: String = Bundle.main.bundleIdentifier ?? "com.rayman.stash") {
        self.service = service
    }

    func string(for account: String) -> String? {
        var query = baseQuery(for: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }

    func set(_ value: String, for account: String) throws {
        guard let data = value.data(using: .utf8) else { return }
        let query = baseQuery(for: account)
        let attributes = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecSuccess {
            return
        }
        if status == errSecItemNotFound {
            var item = query
            item[kSecValueData as String] = data
            let addStatus = SecItemAdd(item as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.unhandledStatus(addStatus)
            }
            return
        }
        throw KeychainError.unhandledStatus(status)
    }

    func remove(_ account: String) throws {
        let status = SecItemDelete(baseQuery(for: account) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledStatus(status)
        }
    }

    private func baseQuery(for account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

extension KeychainStore {
    enum KeychainError: LocalizedError {
        case unhandledStatus(OSStatus)

        var errorDescription: String? {
            switch self {
            case .unhandledStatus(let status):
                return "Keychain operation failed with status \(status)."
            }
        }
    }
}
