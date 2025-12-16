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
    
    private var settingsWindow: NSWindow?
    
    private var collectionWindow: NSWindow?
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        //        NSApp.setActivationPolicy(settingsViewModel.showDockIcon ? .regular : .accessory)
        
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
    }
    
    private func bind() {
        Publishers.CombineLatest4(cabinet.$storedEntries,
                                  cabinet.$recentEntries,
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
        
        NotificationCenter.default.addObserver(forName: .onOutlineViewRowCount, object: nil, queue: nil) { [unowned self] noti in
            guard let height = noti.object as? CGFloat else { return }
            editWindowContentSize(height)
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
            button.image = NSImage(systemSymbolName: "square.stack.3d.up.fill", accessibilityDescription: nil)
        }
    }
    
    private func setupSettingsWindow() {
        let hostingView = NSHostingView(rootView: SettingsView(viewModel: self.settingsViewModel))
        
        settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: hostingView.fittingSize.width, height: hostingView.fittingSize.height),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        settingsWindow?.isReleasedWhenClosed = false
        settingsWindow?.center()
        settingsWindow?.contentView = hostingView
        
    }
    
    private func setupEditWindow() {
        let contentView = ContentView().environmentObject(cabinet)
        let hostingView = NSHostingView(rootView: contentView)
        
        editWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 400),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        editWindow?.title = "Manage"
        editWindow?.isReleasedWhenClosed = false
        editWindow?.center()
        editWindow?.contentView = hostingView
        
        // Post notification when window closes
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: editWindow,
            queue: .main
        ) { [weak self] _ in
            NotificationCenter.default.post(name: .onEditPopoverClose, object: nil)
        }
    }
    
    private func setupCollectionWindow() {
        let collectionView = CollectionView()
        let hostingView = NSHostingView(rootView: collectionView)
        
        collectionWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        collectionWindow?.title = ""
        collectionWindow?.isReleasedWhenClosed = false
        collectionWindow?.center()
        collectionWindow?.contentView = hostingView
        collectionWindow?.minSize = NSSize(width: 900, height: 600)
        
        // Make titlebar transparent so content extends to top
        collectionWindow?.titlebarAppearsTransparent = true
        collectionWindow?.titleVisibility = .hidden
        
        // Use unified compact style for seamless look
        collectionWindow?.toolbarStyle = .unifiedCompact
        
        // Create an empty toolbar to get the proper layout
        let toolbar = NSToolbar(identifier: "CollectionToolbar")
        toolbar.showsBaselineSeparator = false
        collectionWindow?.toolbar = toolbar
    }
    
    @objc func openSettings() {
        if settingsWindow == nil {
            setupSettingsWindow()
        }
        
        // Ensure proper activation and window focusing
        NSApp.activate(ignoringOtherApps: true)
        
        // Use a small delay to ensure app activation completes
        DispatchQueue.main.async {
            self.settingsWindow?.makeKeyAndOrderFront(nil)
            // Force the window to become key window
            self.settingsWindow?.level = .floating
            self.settingsWindow?.level = .normal
            NSApp.arrangeInFront(nil)
        }
    }
    
    @objc func quit() {
        NSApp.terminate(nil)
    }
    
    @objc func edit() {
        if editWindow == nil {
            setupEditWindow()
        }
        
        NSApp.activate(ignoringOtherApps: true)
        
        DispatchQueue.main.async {
            self.editWindow?.makeKeyAndOrderFront(nil)
            self.editWindow?.level = .floating
            self.editWindow?.level = .normal
            NSApp.arrangeInFront(nil)
        }
    }
    
    @objc func openCollection() {
        if collectionWindow == nil {
            setupCollectionWindow()
        }
        
        NSApp.activate(ignoringOtherApps: true)
        
        DispatchQueue.main.async {
            self.collectionWindow?.makeKeyAndOrderFront(nil)
            self.collectionWindow?.level = .floating
            self.collectionWindow?.level = .normal
            NSApp.arrangeInFront(nil)
        }
    }
    
    private func editWindowContentSize(_ height: CGFloat?) {
        let h = height
        ?? outlineViewHeight
        ?? cabinet.storedEntries
            .filter({ $0.parentId == nil })
            .map({ $0.height })
            .reduce(0, { $0 + $1 })
        outlineViewHeight = h
        editWindow?.setContentSize(CGSize(width: 800, height: (h <= 200 ? 200 : h) + 34))
    }
}


