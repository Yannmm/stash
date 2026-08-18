//
//  BaiduPanKeychain.swift
//  Stash
//
//  Created by Rayman on 2026/8/18.
//

import Foundation
import Security

extension Synchronizer.BaiduPanProvider {
    struct Token: Codable {
        var accessToken: String
        var refreshToken: String
    }

    enum Keychain {
        private static let service = "com.nustash.baidupan"
        private static let account = "oauth_token"

        static func save(_ token: Token) throws {
            let data = try JSONEncoder().encode(token)
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
            ]
            SecItemDelete(query as CFDictionary)
            let attrs: [String: Any] = query.merging([
                kSecValueData as String: data,
            ]) { _, new in new }
            let status = SecItemAdd(attrs as CFDictionary, nil)
            guard status == errSecSuccess else {
                throw KeychainError.unhandled(status)
            }
        }

        static func load() -> Token? {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne,
            ]
            var ref: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &ref)
            guard status == errSecSuccess, let data = ref as? Data else { return nil }
            return try? JSONDecoder().decode(Token.self, from: data)
        }

        static func delete() {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
            ]
            SecItemDelete(query as CFDictionary)
        }
    }

    enum KeychainError: Error {
        case unhandled(OSStatus)
    }
}
