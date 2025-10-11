//
//  HotKeyManager.swift
//  Stash
//
//  Created by Rayman on 2025/4/18.
//

import HotKey
import AppKit

class HotKeyManager {
    let action: Action
    
    init(action: Action) {
        self.action = action
    }
    
    private var hotKey: HotKey?

    func register(shortcut: (Key, NSEvent.ModifierFlags)) {
        self.hotKey = nil
        self.hotKey = HotKey(key: shortcut.0, modifiers: shortcut.1, keyDownHandler:  { [weak self] in
            NotificationCenter.default.post(name: .onShortcutKeyDown, object: self?.action)
        })
    }
    
    func unregister() {
        self.hotKey = nil
    }
}

extension HotKeyManager {
    enum Action {
        case menu
        case search
    }
}
