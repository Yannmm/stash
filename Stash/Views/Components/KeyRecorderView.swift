//
//  KeyRecorderView.swift
//  Stash
//
//  Created by Rayman on 2025/4/18.
//

import SwiftUI
import HotKey

struct KeyRecorderView: View {
    @Binding var isRecording: Bool
    @Binding var shortcut: (Key, NSEvent.ModifierFlags)
    
    var body: some View {
        Button(action: {
            isRecording.toggle()
        }) {
            if isRecording {
                Text("Recording...")
                    .foregroundStyle(.secondary)
            } else {
                Text(shortcutString)
                    .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.bordered)
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                guard isRecording, let key = Key(carbonKeyCode: UInt32(event.keyCode)) else { return event }
                shortcut = (key, event.modifierFlags.intersection([.command, .option, .control, .shift]))
                isRecording = false
                return nil
            }
        }
    }
    
    private var shortcutString: String {
        let key = shortcut.0
        let modifiers = shortcut.1
        
        var parts: [String] = []
        
        if modifiers.contains(.control) { parts.append("⌃") }
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.shift) { parts.append("⇧") }
        if modifiers.contains(.command) { parts.append("⌘") }
        
        parts.append(key.description)
        
        return parts.joined()
    }
}
