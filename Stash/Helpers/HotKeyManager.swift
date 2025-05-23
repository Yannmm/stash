//
//  HotKeyManager.swift
//  Stash
//
//  Created by Rayman on 2025/4/18.
//

import HotKey
import AppKit

class HotKeyManager {
    static let shared = HotKeyManager()

    private var hotKey: HotKey?

    func register(shortcut: (Key, NSEvent.ModifierFlags)) {
        self.hotKey = nil
        self.hotKey = HotKey(key: shortcut.0, modifiers: shortcut.1, keyDownHandler:  {
            NotificationCenter.default.post(name: .onShortcutKeyDown, object: nil)
        })
    }
}
