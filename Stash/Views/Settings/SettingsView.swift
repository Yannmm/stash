import SwiftUI
import UniformTypeIdentifiers
import HotKey

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel
    @State private var isRecording = false
    @State private var resetAlert = false
    @State private var fileBackupNotice: String?
    @State private var mergeNotice: String?
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
        if let path = viewModel.exportToFile?.path {
            let tilde = (path as NSString).abbreviatingWithTildeInPath
            var a1 = AttributedString("Recently exported to: ")
            a1.foregroundColor = .secondary
            let a2 = AttributedString(tilde)
            return a1 + a2
        } else {
            return nil
        }
    }
    
    var mergeInGroup: String? {
        guard let path = viewModel.importFromFile else { return nil }
        return String(path.lastPathComponent.split(separator: ".")[0])
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
                    .alert("Import from File", isPresented: $importNotice) {
                        Button("Merge") {
                            handleImport(false)
                        }
                        Button("Replace", role: .destructive) {
                            handleImport(true)
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
                    
                    VStack(alignment: .leading) {
                        if let desc = importDescription {
                            HStack {
                                Text(desc)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                            }
                            Divider()
                        }
                        Text("""
                            Learn how to export bookmarks from [Chrome](Chrome), [Edge](Edge), [Firefox](Firefox) or [Safari](Safari).
                            
                            Click [here](Hungrymark) to import from Hungrymark.
                            
                            Click [here](Pocket) to import from Pocket.
                            """)
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
                                case "Firefox":
                                    howToExport = (browser, "Open the Firefox Library, navigate to \"Import and Backup\", and select \"Export Bookmarks to HTML\".")
                                case "Hungrymark":
                                    let panel = NSOpenPanel()
                                    panel.allowsMultipleSelection = false
                                    panel.canChooseDirectories = false
                                    panel.canCreateDirectories = false
                                    panel.canChooseFiles = true
                                    panel.allowedContentTypes = [UTType(filenameExtension: "txt")!]
                                    
                                    panel.begin { response in
                                        guard response == .OK, let url = panel.url else { return }
                                        self.import(url)
                                    }
                                case "Pocket":
                                    print("import from pocket")
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
                                viewModel.exportDestinationDirectory = url
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
                            do {
                                try viewModel.export()
                                try viewModel.reset()
                                fileBackupNotice = "Done Reset"
                            } catch {
                                viewModel.error = error
                            }
                        }
                    } message: {
                        Text("This action cannot be undone. All your data will be permanently deleted.")
                    }
                }
            }
            .alert(fileBackupNotice ?? "", isPresented: Binding(
                get: { fileBackupNotice != nil },
                set: { if !$0 { fileBackupNotice = nil } }
            )) {
                Button("OK") { }
            } message: {
                Text("Original file is exported to \"Downloads\" as backup, just in case 😉")
            }
            .alert(mergeNotice ?? "", isPresented: Binding(
                get: { mergeNotice != nil },
                set: { if !$0 { mergeNotice = nil } }
            )) {
                Button("OK") { }
            } message: {
                Text("Find them in Group \"\(mergeInGroup ?? "")\" at root level.")
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
                VStack(alignment: .leading) {
                    //                    Link("https://github.com/Yannmm/stash", destination: URL(string: "https://github.com/Yannmm/stash")!)
                    //                        .foregroundStyle(.secondary)
                    //                        .onHover { hovering in
                    //                            if hovering {
                    //                                NSCursor.pointingHand.push()
                    //                            } else {
                    //                                NSCursor.pop()
                    //                            }
                    //                        }
                    Text("[Stashy](stash) is a open-source project. To provide feedback, you may [log issues](repo) or [write email](email) to \(Constant.email).")
                        .foregroundColor(.secondary)
                        .environment(\.openURL, OpenURLAction { url in
                            let browser = url.absoluteString
                            switch browser {
                            case "stash":
                                NSWorkspace.shared.open(URL(string: "https://github.com/Yannmm/stash")!)
                            case "repo":
                                NSWorkspace.shared.open(URL(string: "https://github.com/Yannmm/stash/issues")!)
                            case "email":
                                email()
                            default: break
                            }
                            return .handled
                        })
                }
            }
            
            Section {
                Text("Copyright © 2025 RAP Studio. All rights reserved.")
                    .multilineTextAlignment(.center)
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
    
    private func handleImport(_ replace: Bool) {
        // Handle import
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.html]
        
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            if replace {
                self.import(url)
            } else {
                self.merge(url)
                // 1. parse the file
                // 2. create a new group of file name, add the newly parsed bookmark under the group
                // 3. tell user we are done
                // 4. handle error if necessary
            }
        }
    }
    
    private func `import`(_ url: URL) {
        do {
            try viewModel.export()
            try viewModel.import(url, replace: true)
            fileBackupNotice = "Done Import"
        } catch {
            viewModel.error = error
        }
    }
    
    private func merge(_ url: URL) {
        do {
            try self.viewModel.import(url, replace: false)
            mergeNotice = "Done Merge"
        } catch {
            viewModel.error = error
        }
    }
    
    private func email() {
        let email = Constant.email
        let subject = "Feedback for Stashy App"
        let body = """
        Hi Stashy Team,
        
        I'd like to share some feedback about the app:
        
        1. What I liked:
           - 
        
        2. What could be improved:
           - 
        
        3. Any bugs or issues I encountered:
           - 
        
        Device Information:
        - App Version: x.x.x
        - macOS Version: macOS xx.x
        - Device Model: 
        
        Thanks for making Stashy!
        
        Best regards,
        """
        
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let url = URL(string: "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)") {
            NSWorkspace.shared.open(url)
        }
    }
    
    enum Constant {
        static let email = "yannmm@foxmail.com"
    }
}
