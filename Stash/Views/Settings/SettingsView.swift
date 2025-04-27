import SwiftUI
import HotKey

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel
    @State private var isRecording = false
    @State private var resetAlert = false
    //    @State private var updateFrequency = UpdateFrequency.weekly
    var importDescription: AttributedString {
        if let path = viewModel.importFromFile?.path {
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
        if let path = viewModel.exportToDirectory?.path {
            let tilde = (path as NSString).abbreviatingWithTildeInPath
            var a1 = AttributedString("Recently exported to: ")
            a1.foregroundColor = .secondary
            let a2 = AttributedString(tilde)
            return a1 + a2
        } else {
            return "Select a Destination"
        }
    }
    
    var body: some View {
        Form {
            // General Section
            Section("General") {
                Toggle("Launch on Login", isOn: $viewModel.launchOnLogin)
                Toggle("iCloud Sync", isOn: $viewModel.icloudSync)
                Toggle("Show Icon In Dock", isOn: $viewModel.showDockIcon)
                HStack {
                    Text("Global Shortcut")
                    Spacer()
                    KeyRecorderView(
                        isRecording: $isRecording,
                        shortcut: $viewModel.shortcut
                    )
                }
            }
            Section {
                Toggle(isOn: $viewModel.collapseHistory) {
                    Text("Collapse History")
                }
            } footer: {
                HStack {
                    Text("Show or hide the list of recently-visited bookmarks at the top of menu.")
                        .foregroundColor(.secondary)
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, -4)
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
                        panel.allowedContentTypes = [.html]
                        
                        panel.begin { response in
                            guard response == .OK, let url = panel.url else { return }
                            viewModel.importFromFile = url
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
                            viewModel.exportToDirectory = url
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
                            viewModel.reset()
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
        .alert("Error", isPresented: Binding(
            get: { viewModel.error != nil },
            set: { _ in }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.error?.localizedDescription ?? "")
        }
    }
    
    enum UpdateFrequency: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
    }
}


