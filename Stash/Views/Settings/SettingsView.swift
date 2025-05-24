import SwiftUI
import HotKey

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel
    @State private var isRecording = false
    @State private var resetAlert = false
    @State private var importNotice = false
    @State private var howToExport: (String, String)?
    //    @State private var updateFrequency = UpdateFrequency.weekly
    var importDescription: AttributedString? {
        if let path = viewModel.importFromFile?.path {
            let tilde = (path as NSString).abbreviatingWithTildeInPath
            var a1 = AttributedString("Recently imported from: ")
            a1.foregroundColor = .secondary
            let a2 = AttributedString(tilde)
            return a1 + a2
        }
        return nil
    }
    
    var exportDescription: AttributedString? {
        if let path = viewModel.exportToDirectory?.path {
            let tilde = (path as NSString).abbreviatingWithTildeInPath
            var a1 = AttributedString("Recently exported to: ")
            a1.foregroundColor = .secondary
            let a2 = AttributedString(tilde)
            return a1 + a2
        } else {
            return nil
        }
    }
    
    var body: some View {
        Form {
            // General Section
            Section("General") {
                Toggle("Launch on Login", isOn: $viewModel.launchOnLogin)
                Toggle("iCloud Sync", isOn: $viewModel.icloudSync)
                HStack {
                    Text("Global Shortcut")
                    Spacer()
                    KeyRecorderView(
                        isRecording: $isRecording,
                        shortcut: $viewModel.shortcut
                    )
                }
                VStack(alignment: .leading) {
                    Toggle(isOn: $viewModel.collapseHistory) {
                        Text("Collapse History")
                    }
                    HStack {
                        Text("Show or hide the list of recently-visited bookmarks at the top of menu.")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                }
            }
            
            Section("Data Management") {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Select a File")
                        Spacer()
                        Button("Import") {
                            importNotice = true
                        }
                        .buttonStyle(.bordered)
                    }
                    .alert("Import from Browsers", isPresented: $importNotice) {
                        Button("Continue") {
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
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("You can export from browsers first then import to Stashy.")
                    }
                    .alert("How to Export Bookmarks from \(howToExport?.0 ?? "")", isPresented: Binding(
                        get: { howToExport != nil },
                        set: { if !$0 { howToExport = nil } }
                    )) {
                        Button("OK") {}
                    } message: {
                        Text(howToExport?.1 ?? "")
                    }
                    if let desc = importDescription {
                        HStack {
                            Text(desc)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                    } else {
                        Text("Learn how to export bookmarks from [Chrome](Chrome), [Edge](Edge) or [Safari](Safari).")
                            .foregroundColor(.secondary)
                            .environment(\.openURL, OpenURLAction { url in
                                let browser = url.absoluteString
                                switch browser {
                                case "Chrome":
                                    howToExport = (browser, "Navigate to the Bookmarks Manager, click the three-dot menu, and select \"Export bookmarks\".")
                                case "Edge":
                                    howToExport = (browser, "Open the Favorites window, click the \"More\" button (three dots), then select \"Export Favorites.\".")
                                case "Safari":
                                    howToExport = (browser, "Go to File > Export > Bookmarks, choose a location to save the file, and click Save.")
                                default: break
                                }
                                return .handled
                            })
                    }
                    
                }
                VStack(alignment: .leading) {
                    HStack(spacing: 0) {
                        Text("Select a Destination")
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
                    if let desc = exportDescription {
                        HStack {
                            Text(desc)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                    }
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
            Section("About\(viewModel.versionDescription)") {
//                VStack(alignment: .leading) {
//                    Link("https://github.com/Yannmm/stash", destination: URL(string: "https://github.com/Yannmm/stash")!)
//                        .foregroundStyle(.secondary)
//                        .onHover { hovering in
//                            if hovering {
//                                NSCursor.pointingHand.push()
//                            } else {
//                                NSCursor.pop()
//                            }
//                        }
//                    Text("Stashy is a open-source project. Issues and Pull Requests are welcome.")
//                }
            }
        }
        .navigationTitle("Stashy Settings")
        .scrollIndicators(.hidden)
        .formStyle(.grouped)
        .padding()
        .frame(width: 400)
        .onReceive(NotificationCenter.default.publisher(for: .onShouldOpenImportPanel)) { _ in
            importNotice = true
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
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
