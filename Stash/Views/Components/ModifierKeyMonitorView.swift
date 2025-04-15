//
//  ModifierKeyMonitorView.swift
//  Stash
//
//  Created by Rayman on 2025/4/8.
//

import SwiftUI
import AppKit

struct ModifierKeyMonitorView: NSViewRepresentable {
    let listen: Bool
    
    var modifierKeyManager: ModifierKeyManager {
        return ModifierKeyManager.shared
    }
    
    func makeNSView(context: Context) -> NSView { NSView() }

    func updateNSView(_ nsView: NSView, context: Context) {
         if listen {
             modifierKeyManager.subscribe()
         } else {
             modifierKeyManager.unsubscribe()
         }
    }
}

class ModifierKeyManager {
    
    static let shared = ModifierKeyManager()
    
    private var monitorHandler: Any?
    
    func subscribe() {
        monitorHandler = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
            self.handleModifierFlags(event.modifierFlags)
            return event
        }
    }
    
    func unsubscribe() {
        if let handler = monitorHandler {
            NSEvent.removeMonitor(handler)
        }
    }
    
    private func handleModifierFlags(_ flags: NSEvent.ModifierFlags) {
        NotificationCenter.default.post(name: .onCmdKeyChange, object: flags.containsOnly(.command))
    }
}
