import SwiftUI
import UniformTypeIdentifiers
import HotKey

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel
    @State private var fileBackupNotice: (String, Bool)?
    @State private var appendNotice: String?
    @State private var importFileType: String.FileType? {
        didSet {
            guard let ft = importFileType else { return }
            alert = .import(ft, {
                viewModel.empty
            }, {
                handleImport(true, importFileType)
            }, {
                handleImport(false, importFileType)
            }, {
                handleImport(true, importFileType)
            })
        }
    }
    //    @State private var updateFrequency = UpdateFrequency.weekly
    @State private var alert: SettingsView.Alert = .none
    
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
    
    var appendAsGroup: String? {
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
                    Text("App Global Shortcut")
                    Spacer()
                    KeyRecorderView(
                        isRecording: $viewModel.isAppGlobalShortcutRecording,
                        shortcut: $viewModel.appShortcut
                    )
                }
                HStack {
                    Text("Search Global Shortcut")
                    Spacer()
                    KeyRecorderView(
                        isRecording: $viewModel.isSearchGlobalShortcutRecording,
                        shortcut: $viewModel.searchShortcut
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
                            importFileType = .netscape
                        }
                        .buttonStyle(.bordered)
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
                            Or import from [Pocket](Pocket) and [Hungrymark](Hungrymark).
                            """)
                        .foregroundColor(.secondary)
                        .environment(\.openURL, OpenURLAction { url in
                            let browser = url.absoluteString
                            switch browser {
                            case "Chrome", "Edge", "Safari", "Firefox":
                                alert = .export(browser)
                            case "Hungrymark":
                                importFileType = .hungrymarks
                            case "Pocket":
                                importFileType = .pocket
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
                        alert = Alert.reset {
                            do {
                                try viewModel.export()
                                try viewModel.reset()
                                fileBackupNotice = ("Done Reset", true)
                            } catch {
                                viewModel.error = error
                            }
                        }
                    }, label: {
                        Text("Reset")
                            .foregroundColor(Color(nsColor: .systemRed))
                    })
                    .buttonStyle(.bordered)
                }
            }
            .alert(alert.title, isPresented: Binding(
                get: { alert != .none },
                set: { if !$0 { alert = .none } }
            ), actions: {
                alert.actions()
            }, message: {
                alert.message()
            })
            //            .alert(fileBackupNotice?.0 ?? "", isPresented: Binding(
            //                get: { fileBackupNotice != nil },
            //                set: { if !$0 { fileBackupNotice = nil } }
            //            )) {
            //                Button("OK") { }
            //            } message: {
            //                Text((fileBackupNotice?.1 ?? false) ? "Backup file is exported to \"Downloads\", just in case 😉" : "")
            //            }
            //            .alert(appendNotice ?? "", isPresented: Binding(
            //                get: { appendNotice != nil },
            //                set: { if !$0 { appendNotice = nil } }
            //            )) {
            //                Button("OK") { }
            //            } message: {
            //                Text("Find them in Group \"\(appendAsGroup ?? "")\" at root level.")
            //            }
            
            // Check Update Section
            Section("Software Update") {
                
                // Check update each day
                
                VStack(alignment: .leading) {
                    HStack {
                        Text(viewModel.checkedVersionDescription)
                        Spacer()
                        Button("Go to AppStore") {
                            viewModel.goToAppStore()
                        }
                        .buttonStyle(.bordered)
                    }
                    if let notes = viewModel.newReleaseNotes {
                        HStack {
                            Text(notes)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
            }
            
            // About Section
            Section("About\(viewModel.currentVersionDescription)") {
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
            importFileType = .netscape
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
    
    private func handleImport(_ replace: Bool, _ fileType: String.FileType?) {
        guard let fileType = fileType else {
            self.viewModel.error = SettingsViewModel.SomeError.missingImportFileType
            return
        }
        
        // Handle import
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = fileType.contentTypes
        
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            if replace {
                self.import(url, fileType)
            } else {
                self.append(url, fileType)
                // 1. parse the file
                // 2. create a new group of file name, add the newly parsed bookmark under the group
                // 3. tell user we are done
                // 4. handle error if necessary
            }
        }
    }
    
    private func `import`(_ url: URL, _ fileType: String.FileType) {
        do {
            let flag = viewModel.empty
            if !flag { try viewModel.export() }
            try viewModel.import(url, fileType: fileType, replace: true)
            fileBackupNotice = ("Done Import", !flag)
        } catch {
            viewModel.error = error
        }
    }
    
    private func append(_ url: URL, _ fileType: String.FileType) {
        do {
            try self.viewModel.import(url, fileType: fileType, replace: false)
            appendNotice = "Done Append"
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

extension SettingsView {
    enum Alert: Identifiable, Equatable {
        case none
        case reset(() -> Void)
        case `import`(String.FileType, () -> Bool, () -> Void, () -> Void, () -> Void)
        case export(String)
        case backup
        case append
        case error
        
        var id: String {
            switch(self) {
            case .none: "none"
            case .reset: "reset"
            case .`import`: "import"
            case .export: "export"
            case .backup: "backup"
            case .append: "append"
            case .error: "error"
            }
        }
        
        static func == (lhs: Alert, rhs: Alert) -> Bool {
            switch (lhs, rhs) {
            case (.none, .none), (.reset, .reset), (.`import`, .`import`), (.export, .export), (.backup, .backup), (.append, .append), (.error, .error):
                return true
            default:
                return false
            }
        }
        
        var title: String {
            switch (self) {
            case .none: ""
            case .reset: "Sure to Reset?"
            case .`import`(let ft, _, _, _, _):
                switch ft {
                case .netscape:
                    "Import from File"
                case .hungrymarks:
                    "Import from Hungrymarks"
                case .pocket:
                    "Import from Pocket"
                }
            case .export(let browser):
                "Export Bookmarks from \(browser)"
            case .backup: "xxx"
            case .append: "xxx"
            case .error: "xxx"
            }
        }
        
        @ViewBuilder
        func message() -> some View {
            switch (self) {
            case .none: EmptyView()
            case .reset: Text("This action cannot be undone. All your data will be permanently deleted.")
            case .`import`(let ft, _, _, _, _):
                switch ft {
                case .netscape:
                    Text("Export from another Stashy or browsers first.")
                case .hungrymarks:
                    Text("Go to Settings > Bookmark Files (iCloud/Default > Reveal in Finder, locate the txt file and save it.)")
                case .pocket:
                    Text("Go to \"https://getpocket.com/export\", and click \"Export CSV file\" to download your Pocket saves first.")
                }
            case .export(let browser):
                switch browser {
                case "Chrome":
                    Text("Navigate to the Bookmarks Manager, click the three-dot menu, and select \"Export bookmarks\".")
                case "Edge":
                    Text("Open the Favorites window, click the \"More\" button (three dots), then select \"Export Favorites.\".")
                case "Safari":
                    Text("Go to File > Export > Bookmarks, choose a location to save the file, and click Save.")
                case "Firefox":
                    Text("Open the Firefox Library, navigate to \"Import and Backup\", and select \"Export Bookmarks to HTML\".")
                default: EmptyView()
                }
            case .backup: Text("xxx")
            case .append: Text("xxx")
            case .error: Text("xxx")
            }
        }
        
        @ViewBuilder
        func actions() -> some View {
            
            switch(self) {
            case .none: EmptyView()
            case .reset(let c):
                Button("Cancel", role: .cancel) { }
                Button("Confirm", role: .destructive) {
                    c()
                }
            case .import(_, let empty, let `continue`, let append, let replace):
                if empty() {
                    Button("Continue") {
                        `continue`()
                    }
                } else {
                    Button("Append") {
                        append()
                    }
                    Button("Replace", role: .destructive) {
                        replace()
                    }
                }
                Button("Cancel", role: .cancel) {}
            default:
                EmptyView()
            }
        }
    }
}
