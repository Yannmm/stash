//
//  Pref.swift
//  Stash
//
//  Created by Rayman on 2025/4/18.
//

import Foundation

class Pref {
    private init() {}
    
    struct Entry<Value> {
        fileprivate let rawValue: String
        fileprivate init(_ rawValue: String) {
            self.rawValue = rawValue
        }
    }

    enum Key {
        static let appShortcut = Entry<UInt32>("appShortcut")
        static let appShortcutModifiers = Entry<UInt>("appShortcutModifiers")
        static let searchShortcut = Entry<UInt32>("searchShortcut")
        static let searchShortcutModifiers = Entry<UInt>("searchShortcutModifiers")
        static let collapseHistory = Entry<Bool>("collapseHistory")
        static let icloudSync = Entry<Bool>("icloudSync")
        static let launchOnLogin = Entry<Bool>("launchOnLogin")
        static let showDockIcon = Entry<Bool>("showDockIcon")
        static let recentEntries = Entry<Data>("recentEntries")
        static let recentKeys = Entry<[String]>("recentKeys")
        static let appIdentifier = Entry<String>("appIdentifier")
        static let migration3_0 = Entry<Bool>("migration3_0")
        static let synchronizerApproach = Entry<Synchronizer.Option>("synchronizerApproach")
    }

    static func save<Value>(for key: Entry<Value>, value: Value?) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }

    static func value<Value>(for key: Entry<Value>) -> Value? {
        UserDefaults.standard.value(forKey: key.rawValue) as? Value
    }
}

extension Pref {
    static func save<Value: RawRepresentable>(
        for key: Entry<Value>,
        value: Value?
    ) {
        UserDefaults.standard.set(value?.rawValue, forKey: key.rawValue)
    }

    static func value<Value: RawRepresentable>(
        for key: Entry<Value>
    ) -> Value? {
        guard let rawValue = UserDefaults.standard.object(forKey: key.rawValue)
                as? Value.RawValue
        else {
            return nil
        }

        return Value(rawValue: rawValue)
    }
}
