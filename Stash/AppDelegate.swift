//
//  AppDelegate.swift
//  Stash
//
//  Created by Rayman on 2025/2/10.
//

import AppKit
import SwiftUI
import Combine
import HotKey
import Kingfisher
import Carbon
import SwiftyDropbox

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    
    internal var statusItem: NSStatusItem?
    
    internal var dropWindow: NSWindow?
    
    internal var searchPanel: FloatingPanel!
    
    internal var searchPanelPosition: CGPoint?
    
    private var editWindow: NSWindow?
    
    private lazy var settingsViewModel: SettingsViewModel = {
        let viewModel = SettingsViewModel(cabinet: cabinet, updateChecker: updateChecker)
        return viewModel
    }()
    
    internal lazy var searchViewModel: SearchViewModel = {
        let viewModel = SearchViewModel(cabinet: cabinet)
        return viewModel
    }()
    
    var cabinet: OkamuraCabinet { OkamuraCabinet.shared }
    
    private var updateChecker: UpdateChecker { UpdateChecker.shared }
    
    private let dominator = Dominator()
    
    private var cancellables = Set<AnyCancellable>()
    
    private var outlineViewHeight: CGFloat?
    
    private var window1: NSWindow?
    
    private var window2: NSWindow?
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        //                NSApp.setActivationPolicy(settingsViewModel.showDockIcon ? .regular : .accessory)
        NSApp.setActivationPolicy(.accessory)
        //        NSAppleEventManager.shared().setEventHandler(
        //            self,
        //            andSelector: #selector(handleGetURLEvent(_:withReplyEvent:)),
        //            forEventClass: AEEventClass(kInternetEventClass),
        //            andEventID: AEEventID(kAEGetURL)
        //        )
        
        // TODO: remove this line
        //        ImageCache.default.diskStorage.config.expiration = .days(1)
        //        ImageCache.default.clearDiskCache()
        
        Task {
            try? await updateChecker.check()
        }
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        
        bind()
        
        setupUpdateCheckTimer()
        cabinet.syncCoordinator.startBackgroundRefresh()
        
        DropboxClientsManager.setupWithAppKeyDesktop("y6ijm2p3vqr7kt8")
        
        NSAppleEventManager.shared().setEventHandler(self,
                                                     andSelector: #selector(handleGetURLEvent1),
                                                     forEventClass: AEEventClass(kInternetEventClass),
                                                     andEventID: AEEventID(kAEGetURL))
    }
    
    @objc func handleGetURLEvent1(_ event: NSAppleEventDescriptor?, replyEvent: NSAppleEventDescriptor?) {
        if let aeEventDescriptor = event?.paramDescriptor(forKeyword: AEKeyword(keyDirectObject)) {
            if let urlStr = aeEventDescriptor.stringValue {
                let url = URL(string: urlStr)!
                let oauthCompletion: DropboxOAuthCompletion = {
                    if let authResult = $0 {
                        switch authResult {
                        case .success:
                            print("Success! User is logged into Dropbox.")
                        case .cancel:
                            print("Authorization flow was manually canceled by user!")
                        case .error(_, let description):
                            print("Error: \(String(describing: description))")
                        }
                    }
                }
                DropboxClientsManager.handleRedirectURL(url, includeBackgroundClient: false, completion: oauthCompletion)
                // this brings your application back the foreground on redirect
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    private func handleIncomingURL(_ url: URL) {
        if (url.scheme ?? "").hasPrefix("db-") {
            DropboxClientsManager.handleRedirectURL(
                url,
                backgroundSessionIdentifier: ""
            ) { result in
                guard let result = result else { return }
                switch result {
                case .success:
                    print("✅ Logged into Dropbox")
                case .cancel:
                    print("❌ User cancelled")
                case .error(_, let description):
                    print("⚠️ Error: \(description)")
                }
            }
            return
        }
        
        cabinet.syncCoordinator.handleOAuthCallback(url)
    }
    
    private func bind() {
        Publishers.CombineLatest4(cabinet.$storedEntries,
                                  cabinet.$recentEntries,
                                  settingsViewModel.$collapseHistory,
                                  NSApp.publisher(for: \.effectiveAppearance))
        .sink {  tuple5 in
            Task { @MainActor [weak self] in
                self?.statusItem?.menu = self?.generateMenu(from: tuple5.0, history: tuple5.1, collapseHistory: tuple5.2)
            }
        }
        .store(in: &cancellables)
        
        // Notifications
        NotificationCenter.default.addObserver(
            forName: .onShortcutKeyDown,
            object: nil,
            queue: nil
        ) { [weak self] noti in
            guard let action = noti.object as? HotKeyManager.Action else { return }
            
            Task { @MainActor [weak self] in
                switch action {
                case .menu:
                    if let button = self?.statusItem?.button {
                        button.performClick(nil)
                    }
                    
                case .search:
                    self?.search()
                }
            }
        }
        
        NotificationCenter.default.addObserver(forName: .onDragWindow, object: nil, queue: nil) { noti in
            guard let panel = noti.object as? NSPanel else { return }
            Task { @MainActor [weak self] in
                self?.searchPanelPosition = CGPoint(x: panel.frame.origin.x + panel.frame.width, y: panel.frame.origin.y + panel.frame.height)
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSApplication.didBecomeActiveNotification, object: nil, queue: nil) { _ in
            Task { @MainActor [weak self] in
                self?.cabinet.syncCoordinator.handleDidBecomeActive()
            }
            
        }
    }
    
    private func setupUpdateCheckTimer() {
        Timer.publish(every: 3 * 60 * 60, on: .main, in: .common)
            .autoconnect()
            .prepend(Date())
            .sink { [unowned self] _ in
                Task {
                    do {
                        try await self.updateChecker.check()
                    } catch {
                        ErrorTracker.shared.add(error)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(named: "forest")
        }
    }
    
    private func setupWindow1() {
        let hostingView = NSHostingView(rootView: SettingsView(viewModel: self.settingsViewModel))
        
        window1 = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: hostingView.fittingSize.width, height: hostingView.fittingSize.height),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window1?.isReleasedWhenClosed = false
        window1?.center()
        window1?.contentView = hostingView
        
    }
    
    private func setupWindow2() {
        let manageView = ManageView(wrapper: GroupSelectionWrapper())
            .environmentObject(cabinet)
        let hostingView = NSHostingView(rootView: manageView)
        
        window2 = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
            styleMask: [
                .titled,
                .closable,
                .miniaturizable,
                .resizable,
                .fullSizeContentView
            ],
            backing: .buffered,
            defer: false
        )
        
        window2?.title = ""
        window2?.titleVisibility = .hidden
        window2?.titlebarAppearsTransparent = true
        window2?.isReleasedWhenClosed = false
        window2?.center()
        window2?.contentView = hostingView
        window2?.minSize = NSSize(width: 900, height: 600)
        
        // 🔑 IMPORTANT
        window2?.toolbarStyle = .unified   // ← not unifiedCompact
        
        let toolbar = NSToolbar(identifier: "CollectionToolbar")
        toolbar.displayMode = .iconOnly
        toolbar.showsBaselineSeparator = false
        toolbar.allowsUserCustomization = false
        toolbar.isVisible = true
        
        window2?.toolbar = toolbar
    }
    
    @objc func settings() {
        if window1 == nil {
            setupWindow1()
            observeWindowClose(window1)
        }
        
        // Show dock icon
        NSApp.setActivationPolicy(.regular)
        
        // Ensure proper activation and window focusing
        NSApp.activate(ignoringOtherApps: true)
        
        // Use a small delay to ensure app activation completes
        DispatchQueue.main.async {
            self.window1?.makeKeyAndOrderFront(nil)
            self.window1?.level = .floating
            self.window1?.level = .normal
            NSApp.arrangeInFront(nil)
        }
    }
    
    @objc func quit() {
        NSApp.terminate(nil)
    }
    
    @objc func manage() {
        if window2 == nil {
            setupWindow2()
            observeWindowClose(window2)
        }
        
        // Show dock icon
        NSApp.setActivationPolicy(.regular)
        
        NSApp.activate(ignoringOtherApps: true)
        
        DispatchQueue.main.async {
            self.window2?.makeKeyAndOrderFront(nil)
            self.window2?.level = .floating
            self.window2?.level = .normal
            NSApp.arrangeInFront(nil)
        }
    }
    
    private func observeWindowClose(_ window: NSWindow?) {
        guard let window = window else { return }
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) {  notification in
            guard let closingWindow = notification.object as? NSWindow else { return }
            Task { @MainActor [weak self] in
                self?.updateDockIconVisibility(excluding: closingWindow)
            }
        }
    }
    
    private func updateDockIconVisibility(excluding closingWindow: NSWindow) {
        // Check visibility excluding the window that's closing
        let settingsVisible = (window1 != nil && window1 !== closingWindow && window1!.isVisible)
        let collectionVisible = (window2 != nil && window2 !== closingWindow && window2!.isVisible)
        
        if !settingsVisible && !collectionVisible {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}


