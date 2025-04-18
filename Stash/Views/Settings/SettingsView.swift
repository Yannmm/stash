import SwiftUI
import HotKey

struct SettingsView: View {
    @State private var isRecording = false
    @State private var currentKey: Key = .r
    @State private var currentModifiers: NSEvent.ModifierFlags = [.command, .option]
    
    @State private var launchOnLogin = false
    @State private var iCloudSync = false
    @State private var updateFrequency = UpdateFrequency.weekly
    
    enum UpdateFrequency: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
    }
    
    var body: some View {
        Form {
            // General Section
            Section("General") {
                Toggle("Launch on Login", isOn: $launchOnLogin)
                
                HStack {
                    Text("Global Shortcut")
                    Spacer()
                    KeyRecorderView(
                        isRecording: $isRecording,
                        key: $currentKey,
                        modifiers: $currentModifiers
                    )
                }
                
                Toggle("iCloud Sync", isOn: $iCloudSync)
                
                Button("Import...") {
                    // Handle import
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    panel.canCreateDirectories = false
                    panel.canChooseFiles = true
                    panel.allowedContentTypes = [.json]
                    
                    panel.begin { response in
                        if response == .OK, let url = panel.url {
                            // Handle the selected file URL
                            print("Selected file: \(url)")
                        }
                    }
                }
            }
            
            // Check Update Section
            Section("Data Management") {
                Button("Import") {
                    // Handle update check
                }
                .buttonStyle(.bordered)
                
                Picker("Check frequency:", selection: $updateFrequency) {
                    ForEach(UpdateFrequency.allCases, id: \.self) { frequency in
                        Text(frequency.rawValue).tag(frequency)
                    }
                }
            }
            
            // Check Update Section
            Section("Software Update") {
                HStack {
                    Button("Check for Updates") {
                        // Handle update check
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Text("Last checked date...")
                }
                
                Picker("Check frequency:", selection: $updateFrequency) {
                    ForEach(UpdateFrequency.allCases, id: \.self) { frequency in
                        Text(frequency.rawValue).tag(frequency)
                    }
                }
            }
            
            // About Section
            Section("About") {
                Link("www.github.com", destination: URL(string: "https://www.github.com")!)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 400)
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
