//
//  PieceSaver.swift
//  Stash
//
//  Created by Rayman on 2025/4/18.
//

import Foundation

class PieceSaver {
    enum Key: String {
        case appShortcut
        case appShortcutModifiers
        case searchShortcut
        case searchShortcutModifiers
        case collapseHistory
        case icloudSync
        case launchOnLogin
        case showDockIcon
        case recentEntries
        case recentKeys
        case appIdentifier
        case syncMethod
        case syncCheckpoint
        case syncLastDate
        case baiduClientID
        case baiduRedirectURI
        case baiduRemoteDirectory
        case baiduOAuthState
        
        case migration3_0
    }

    func save(for key: Key, value: Any?) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }
    
    func value<T>(for key: Key) -> T? {
        UserDefaults.standard.value(forKey: key.rawValue) as? T
    }

    func saveCodable<T: Encodable>(_ value: T?, for key: Key) throws {
        if let value {
            let data = try JSONEncoder().encode(value)
            save(for: key, value: data)
        } else {
            save(for: key, value: nil)
        }
    }

    func codableValue<T: Decodable>(for key: Key, as type: T.Type) -> T? {
        guard let data: Data = value(for: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
