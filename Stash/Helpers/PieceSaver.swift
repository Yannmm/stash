//
//  PieceSaver.swift
//  Stash
//
//  Created by Rayman on 2025/4/18.
//

import Foundation

class PieceSaver {
    enum Key: String {
        case hotkey
        case hokeyModifiers
    }
    
    func save(for key: Key, value: Any?) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }
    
    func value(for key: Key) -> Any? {
        UserDefaults.standard.value(forKey: key.rawValue)
    }
}
