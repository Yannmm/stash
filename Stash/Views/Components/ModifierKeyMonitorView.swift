//
//  ModifierKeyMonitorView.swift
//  Stash
//
//  Created by Rayman on 2025/4/8.
//

import SwiftUI

struct ModifierKeyMonitorView: NSViewRepresentable {
    @Binding var on: Bool
    
    var modifierKeyManager: ModifierKeyManager {
        return ModifierKeyManager.shared
    }
    
    func makeNSView(context: Context) -> NSView { NSView() }

    func updateNSView(_ nsView: NSView, context: Context) {
         if on {
             modifierKeyManager.subscribe()
         } else {
             modifierKeyManager.unsubscribe()
         }
    }
}
