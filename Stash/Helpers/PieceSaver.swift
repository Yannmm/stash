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
    }

    func save(for key: Key, value: Any?) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }
    
    func value<T>(for key: Key) -> T? {
        UserDefaults.standard.value(forKey: key.rawValue) as? T
    }
}
