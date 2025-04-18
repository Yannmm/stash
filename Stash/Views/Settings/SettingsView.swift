import SwiftUI
import HotKey

struct SettingsView: View {
    @State private var isRecording = false
    @State var shortcut: (Key, NSEvent.ModifierFlags)
    
    var shortcutHash: Int {
        let a = shortcut.0.carbonKeyCode
        let b = shortcut.1.rawValue
        
        var hasher = Hasher()
        hasher.combine(a)
        hasher.combine(b)
        return hasher.finalize()
    }
    
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
                        shortcut: $shortcut
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
        .scrollIndicators(.hidden)
        .formStyle(.grouped)
        .padding()
        .frame(width: 400)
        .onChange(of: shortcutHash) {
            HotKeyManager.shared.update(key: shortcut.0, modifiers: shortcut.1)
        }
    }
}


