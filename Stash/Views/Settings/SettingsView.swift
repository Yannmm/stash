import SwiftUI
import HotKey

struct SettingsView: View {
    @State private var isRecording = false
    @State private var dockIcon = true
    @State var shortcut: (Key, NSEvent.ModifierFlags)
    @State var importFilePath: URL?
    @State var exportFilePath: URL?
    
    let onSelectImportFile: (URL) -> Void
    let onSelectExportDestination: (URL) throws -> URL
    let onReset: () -> Void
    let onChangeDockIcon: (Bool) -> Void
 
    var importDescription: AttributedString {
        if let path = importFilePath?.path {
            let tilde = (path as NSString).abbreviatingWithTildeInPath
            var a1 = AttributedString("Recently imported from: ")
            a1.foregroundColor = .secondary
            let a2 = AttributedString(tilde)
            return a1 + a2
        } else {
            return "Select a File"
        }
    }
    
    var exportDescription: AttributedString {
        if let path = exportFilePath?.path {
            let tilde = (path as NSString).abbreviatingWithTildeInPath
            var a1 = AttributedString("Recently exported to: ")
            a1.foregroundColor = .secondary
            let a2 = AttributedString(tilde)
            return a1 + a2
        } else {
            return "Select a Destination"
        }
    }
    
    var shortcutHash: Int {
        let a = shortcut.0.carbonKeyCode
        let b = shortcut.1.rawValue
        
        var hasher = Hasher()
        hasher.combine(a)
        hasher.combine(b)
        return hasher.finalize()
    }
    
    @State private var launchOnLogin = false
    @State private var icloudSync = false
    @State private var updateFrequency = UpdateFrequency.weekly
    @State private var resetAlert = false
    
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
                Toggle("iCloud Sync", isOn: $icloudSync)
                Toggle("Show Icon In Dock", isOn: $dockIcon)
                HStack {
                    Text("Global Shortcut")
                    Spacer()
                    KeyRecorderView(
                        isRecording: $isRecording,
                        shortcut: $shortcut
                    )
                }
            }
            
            // Check Update Section
            Section("Data Management") {
                HStack {
                    Text(importDescription)
                    Spacer()
                    Button("Import") {
                        // Handle import
                        let panel = NSOpenPanel()
                        panel.allowsMultipleSelection = false
                        panel.canChooseDirectories = false
                        panel.canCreateDirectories = false
                        panel.canChooseFiles = true
                        panel.allowedContentTypes = [.json]
                        
                        panel.begin { response in
                            guard response == .OK, let url = panel.url else { return }
                            importFilePath = url
                            onSelectImportFile(url)
                        }
                    }
                    .buttonStyle(.bordered)
                }
                
                HStack(spacing: 0) {
                    Text(exportDescription)
                    Spacer()
                    Button("Export") {
                        // Handle import
                        let panel = NSOpenPanel()
                        panel.allowsMultipleSelection = false
                        panel.canChooseDirectories = true
                        panel.canCreateDirectories = true
                        panel.canChooseFiles = false
                        
                        panel.begin { response in
                            guard response == .OK, let url = panel.url else { return }
                            do {
                                exportFilePath = try onSelectExportDestination(url)
                            } catch {
                                print("save to disk failed")
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                }
                
                HStack {
                    Text("Clear All Data")
                    Spacer()
                    Button(action: {
                        resetAlert = true
                    }, label: {
                        Text("Reset")
                            .foregroundColor(Color(nsColor: .systemRed))
                    })
                    .buttonStyle(.bordered)
                    .alert("Sure to Reset?", isPresented: $resetAlert) {
                        Button("Cancel", role: .cancel) { }
                        Button("Confirm", role: .destructive) {
                            onReset()
                        }
                    } message: {
                        Text("This action cannot be undone. All your data will be permanently deleted.")
                    }
                }
            }
            
            // Check Update Section
//            Section("Software Update") {
//                HStack {
//                    Button("Check for Updates") {
//                        // Handle update check
//                    }
//                    .buttonStyle(.bordered)
//                    
//                    Spacer()
//                    
//                    Text("Last checked date...")
//                }
//                
//                Picker("Check frequency:", selection: $updateFrequency) {
//                    ForEach(UpdateFrequency.allCases, id: \.self) { frequency in
//                        Text(frequency.rawValue).tag(frequency)
//                    }
//                }
//            }
            
            // About Section
            Section("About") {
                Link("https://github.com/Yannmm/stash", destination: URL(string: "https://github.com/Yannmm/stash")!)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Stash Settings")
        .scrollIndicators(.hidden)
        .formStyle(.grouped)
        .padding()
        .frame(width: 400)
        .onChange(of: shortcutHash) {
            HotKeyManager.shared.update(key: shortcut.0, modifiers: shortcut.1)
        }
        .onChange(of: dockIcon) { _, flag in
            onChangeDockIcon(flag)
        }
    }
}


