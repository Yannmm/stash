//
//  ModifierKeyMonitorView.swift
//  Stash
//
//  Created by Rayman on 2025/4/8.
//

import SwiftUI
import AppKit

struct ModifierKeyMonitorView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        
        // Add local event monitor
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
            self.handleModifierFlags(event.modifierFlags)
            return event
        }
        
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    private func handleModifierFlags(_ flags: NSEvent.ModifierFlags) {
        let result = flags.intersection(.deviceIndependentFlagsMask) == .command
        NotificationCenter.default.post(name: .onCmdKeyChange, object: result)
    }
}

