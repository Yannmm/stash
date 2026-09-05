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

class AppDelegate: NSObject, NSApplicationDelegate {
    
    internal var statusItem: NSStatusItem?
    
    internal var dropWindow: NSWindow?
    
    internal var searchPanel: FloatingPanel!
    
    internal var searchPanelPosition: CGPoint?
    
    private var editWindow: NSWindow?
    
    internal var settingsViewModel: SettingsViewModel!
    
    internal var searchViewModel: SearchViewModel!
    
    internal var housekeeper: Housekeeper!
    
    private var updateChecker: UpdateChecker { UpdateChecker.shared }
    
    private var cancellables = Set<AnyCancellable>()
    
    private var outlineViewHeight: CGFloat?
    
    private var window1: NSWindow?
    
    private var window2: NSWindow?
    
    private func initialize() {
        let savedApproach = Pref.value(for: Pref.Key.synchronizerApproach) ?? Synchronizer.Option.local
        let localProvider = Synchronizer.OnPremiseProvider()
        let providers: [Synchronizer.Option: any Synchronizer.Provider] = [
            .local: localProvider,
            .dropbox: Synchronizer.DropboxProvider(),
            .icloud: Synchronizer.AiCloudProvider(),
            .baidupan: Synchronizer.BaiduPanProvider(),
        ]
        let synchronizer = Synchronizer(
            approach: savedApproach,
            providers: providers,
            localProvider: localProvider
        )
        // TODO: can we remove prepare here??????
        if savedApproach != .local, let remote = providers[savedApproach] {
            Task { try? await remote.prepare() }
        }
        
        let hk = Housekeeper(synchronizer: synchronizer)
        self.housekeeper = hk
        
        let svm = SettingsViewModel(
            provider: savedApproach,
            onReset: {
                try hk.removeAll()
            },
            onImport: { from, fileType, replace in
                try hk.import(from: from, fileType: fileType, replace: replace)
            },
            onExport: { to, suffix in
                try hk.export(to: to, suffix: suffix)
            },
            onApproachChange: { approach in
                synchronizer.setApproach(approach)
            })
        
        synchronizer.availability.sink { availability in
            Task { @MainActor in
                svm.availability = availability
            }
        }.store(in: &cancellables)
        
        self.settingsViewModel = svm
        
        self.searchViewModel = SearchViewModel(housekeeper: hk)
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {}
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        NSAppleEventManager.shared().setEventHandler(self,
                                                     andSelector: #selector(handleGetURLEvent(_:replyEvent:)),
                                                     forEventClass: AEEventClass(kInternetEventClass),
                                                     andEventID: AEEventID(kAEGetURL))
        
        initialize()
        
        Task {
            try? await updateChecker.check()
        }
    }
    
    @objc private func handleGetURLEvent(_ event: NSAppleEventDescriptor?,
        replyEvent: NSAppleEventDescriptor?) {
        guard let descriptor = event?.paramDescriptor(forKeyword: AEKeyword(keyDirectObject)),
              let urlStr = descriptor.stringValue,
              let url = URL(string: urlStr) else { return }
        NotificationCenter.default.post(name: .onUrlEvent, object: url)
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        
        bind()
        
        setupUpdateCheckTimer()
    }
    
    private func bind() {
        Publishers.CombineLatest4(housekeeper.$storedEntries,
                                  housekeeper.$recentEntries,
                                  settingsViewModel.$collapseHistory,
                                  NSApp.publisher(for: \.effectiveAppearance))
        .sink { [weak self] tuple5 in
            Task { @MainActor in
                self?.statusItem?.menu = self?.generateMenu(from: tuple5.0, history: tuple5.1, collapseHistory: tuple5.2)
            }
        }
        .store(in: &cancellables)
        
        
        // Notifications
        NotificationCenter.default.addObserver(forName: .onShortcutKeyDown, object: nil, queue: nil) { [weak self] noti in
            guard let action = noti.object as? HotKeyManager.Action else { return }
            switch action {
            case .menu:
                if let button = self?.statusItem?.button {
                    button.performClick(nil)
                }
            case .search:
                self?.search()
            }
            
        }
        
        NotificationCenter.default.addObserver(forName: .onDragWindow, object: nil, queue: nil) { [weak self] noti in
            //            guard let p1 = noti.object as? FloatingPanel,
            //                  let p2 = self?.searchPanel,
            //                  p1 === p2 else { return }
            guard let panel = noti.object as? NSPanel else { return }
            self?.searchPanelPosition = CGPoint(x: panel.frame.origin.x + panel.frame.width, y: panel.frame.origin.y + panel.frame.height)
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
            //            button.image = NSImage(systemSymbolName: "square.stack.3d.up.fill", accessibilityDescription: nil)
            button.image = NSImage(named: "forest")
        }
    }
    
    private func setupWindow1() {
        let hostingView = NSHostingView(rootView: SettingsView(viewModel: self.settingsViewModel, updateChcker: self.updateChecker))
        
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
            .environmentObject(housekeeper)
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
        guard let window = window1 else { return }
        _openWindow(window)
    }
    
    @objc func quit() {
        NSApp.terminate(nil)
    }
    
    @objc func manage() {
        if window2 == nil {
            setupWindow2()
            observeWindowClose(window2)
        }
        guard let window = window2 else { return }
        _openWindow(window)
    }
    
    private func _openWindow(_ window: NSWindow) {
        // Convert accessory app to foreground app
        NSApp.setActivationPolicy(.regular)
        
        // Activate app FIRST
        NSApp.activate(ignoringOtherApps: true)
        
        DispatchQueue.main.async {
            // Ensure window can participate in activation
            window.collectionBehavior.remove(.transient)
            
            // Bring window forward
            window.makeKeyAndOrderFront(nil)
            
            // Important for Stage Manager
            window.orderFrontRegardless()
        }
    }
    
    private func observeWindowClose(_ window: NSWindow?) {
        guard let window = window else { return }
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] notification in
            guard let closingWindow = notification.object as? NSWindow else { return }
            self?.updateDockIconVisibility(excluding: closingWindow)
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


