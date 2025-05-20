//
//  ModifierKeyManager.swift
//  Stash
//
//  Created by Yan Meng on 2025/5/20.
//

import AppKit

class ModifierKeyManager {
    static let shared = ModifierKeyManager()
    
    private var handler: Any?
    private var subscribed = false
    
    func subscribe() {
        guard !subscribed else { return }
        subscribed = true
        handler = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleModifierFlags(event.modifierFlags)
            return event
        }
    }
    
    func unsubscribe() {
        guard subscribed else { return }
        subscribed = false
        if let handler = handler {
            NSEvent.removeMonitor(handler)
            self.handler = nil
        }
    }
    
    private func handleModifierFlags(_ flags: NSEvent.ModifierFlags) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .onCmdKeyChange, object: flags.containsOnly(.command))
        }
    }
}
