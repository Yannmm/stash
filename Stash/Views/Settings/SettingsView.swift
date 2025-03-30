import SwiftUI
import HotKey

struct SettingsView: View {
    @State private var isRecording = false
    @State private var currentKey: Key = .r
    @State private var currentModifiers: NSEvent.ModifierFlags = [.command, .option]
    
    var body: some View {
        Form {
            Section("Keyboard Shortcuts") {
                HStack {
                    Text("Toggle Stash:")
                    Spacer()
                    KeyRecorderView(
                        isRecording: $isRecording,
                        key: $currentKey,
                        modifiers: $currentModifiers
                    )
                }
            }
        }
        .padding()
        .frame(width: 400, height: 200)
    }
}

struct KeyRecorderView: View {
    @Binding var isRecording: Bool
    @Binding var key: Key
    @Binding var modifiers: NSEvent.ModifierFlags
    
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
                guard isRecording else { return event }
                
                if let newKey = Key(carbonKeyCode: UInt32(event.keyCode)) {
                    key = newKey
                    modifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])
                    isRecording = false
                    return nil
                }
                return event
            }
        }
    }
    
    private var shortcutString: String {
        var parts: [String] = []
        
        if modifiers.contains(.control) { parts.append("⌃") }
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.shift) { parts.append("⇧") }
        if modifiers.contains(.command) { parts.append("⌘") }
        
//        parts.append(key.stringValue)
        
        return parts.joined()
    }
} 
