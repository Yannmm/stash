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
    
    func register() {}
    
    
    func update(key: Key, modifiers: NSEvent.ModifierFlags) {
        pieceSaver.save(for: .hotkey, value: key.carbonKeyCode)
        pieceSaver.save(for: .hokeyModifiers, value: modifiers.rawValue)
        
        _shortcut = (key, modifiers)
        
        hotKey = HotKey(key: key, modifiers: modifiers, keyDownHandler:  {
            NotificationCenter.default.post(name: .onShortcutKeyDown, object: nil)
        })
    }
    
    var shortcut: (Key, NSEvent.ModifierFlags) { _shortcut  }
    
    private var _shortcut: (Key, NSEvent.ModifierFlags)
    
    private let pieceSaver = PieceSaver()
    
    private var hotKey: HotKey
    
    private init() {
        var key: Key?
        if let saved = pieceSaver.value(for: .hotkey) as? UInt32 {
            key = Key(carbonKeyCode: saved)
        }
        if key == nil {
            key = Key(string: "s")
        }
        
        var modifiers: NSEvent.ModifierFlags?
        if let saved = pieceSaver.value(for: .hokeyModifiers) as? UInt {
            modifiers = NSEvent.ModifierFlags(rawValue: saved)
        }
        if modifiers == nil {
            modifiers = NSEvent.ModifierFlags([.shift, .command])
        }
        
        self._shortcut = (key!, modifiers!)
        
        self.hotKey = HotKey(key: key!, modifiers: modifiers!, keyDownHandler:  {
            NotificationCenter.default.post(name: .onShortcutKeyDown, object: nil)
        })
    }
}
