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
        if flags.contains(.shift) {
            print("Shift key is down")
        } else {
            print("Shift key is up")
        }

        if flags.contains(.command) {
            print("Command key is down")
        }
    }
}

