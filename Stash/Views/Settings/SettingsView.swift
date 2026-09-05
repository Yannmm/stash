import SwiftUI
import UniformTypeIdentifiers
import HotKey

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel
    
    @StateObject var updateChcker: UpdateChecker
    
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
    
    private func synchronizerApproachDescription(_ approach: Synchronizer.Option) -> String {
        switch approach {
        case .local: return "Local"
        case .icloud: return "iCloud"
        case .dropbox: return "Dropbox"
        case .baidupan: return "BaiduPan"
        }
    }
    
    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch on Login", isOn: $viewModel.launchOnLogin)
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
            
            Section("Synchronization") {
                VStack(alignment: .leading) {
                    Picker("Approach", selection: $viewModel.synchronizerApproach) {
                        ForEach(Synchronizer.Option.allCases) { approach in
                            Text(synchronizerApproachDescription(approach))
//                                .foregroundColor(viewModel.synchronizerApproach == approach ? .theme : .primary)
                                .tag(approach)
                        }
                    }
                    Text(viewModel.availability.describe())
                        .environment(\.openURL, OpenURLAction { url in
                            viewModel.availability.action(url.absoluteString)
                            return .handled
                        })
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
                            Or import from [Pocket](Pocket) and [Hungrymarks](Hungrymark).
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
                                alert = .backup("Done Reset", true)
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
            
            // Check Update Section
            Section("Software Update") {
                
                // Check update each day
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("\(updateChcker.new != nil ? "New Version Available: \(updateChcker.new!.version)" : "You're Up to Date")")
                        Spacer()
                        Button("Go to AppStore") {
                            updateChcker.go()
                        }
                        .buttonStyle(.bordered)
                    }
                    if let notes = updateChcker.new?.releaseNotes {
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
                    Text("[Nustash](stash) is a open-source project. To provide feedback, you may [log issues](repo) or [write email](email) to \(Constant.email).")
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
                Text("Copyright © 2026 RAP Studio. All rights reserved.")
                    .multilineTextAlignment(.center)
            }
        }
        .navigationTitle("Nustash Settings")
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
            alert = .backup("Done Import", !flag)
        } catch {
            viewModel.error = error
        }
    }
    
    private func append(_ url: URL, _ fileType: String.FileType) {
        do {
            try self.viewModel.import(url, fileType: fileType, replace: false)
            alert = .append(appendAsGroup)
        } catch {
            viewModel.error = error
        }
    }
    
    private func email() {
        let email = Constant.email
        let subject = "Feedback for Nustash App"
        let body = """
        Hi Nustash Team,
        
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
        
        Thanks for making Nustash!
        
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
        case backup(String, Bool)
        case append(String?)
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
            case .backup(let title, _):
                title
            case .append: "Done Append"
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
                    Text("Export from another Nustash or browsers first.")
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
            case .backup(_, let flag):
                Text(flag ? "Backup file is exported to \"Downloads\", just in case 😉" : "")
            case .append(let group):
                Text("Find them in Group \"\(group ?? "")\" at root level.")
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
            case .export(_):
                Button("OK", role: .cancel) {}
            case .backup(_, _):
                Button("OK", role: .cancel) { }
            case .append(_):
                Button("OK", role: .cancel) { }
            case .error:
                EmptyView()
            }
        }
    }
}
