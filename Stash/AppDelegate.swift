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

var xx: AppDelegate?

class AppDelegate: NSObject, NSApplicationDelegate {
    
    internal var statusItem: NSStatusItem?
    
    internal var dropWindow: NSWindow?
    
    internal var searchPanel: NSPanel!
    
    private lazy var editPopover: NSPopover = {
        let p = NSPopover()
        let contentView = ContentView().environmentObject(cabinet)
        p.behavior = .transient
        p.contentViewController = NSHostingController(rootView: contentView)
        p.delegate = self
        return p
    }()
    
    private lazy var settingsViewModel: SettingsViewModel = {
        let viewModel = SettingsViewModel(hotKeyManager: hotKeyMananger, cabinet: cabinet)
        return viewModel
    }()
    
    internal lazy var searchViewModel: SearchViewModel = {
        let viewModel = SearchViewModel()
        return viewModel
    }()
    
    var cabinet: OkamuraCabinet { OkamuraCabinet.shared }
    
    var hotKeyMananger: HotKeyManager { HotKeyManager.shared }
    
    private let dominator = Dominator()
    
    private var cancellables = Set<AnyCancellable>()
    
    private var outlineViewHeight: CGFloat?
    
    private var settingsWindow: NSWindow?
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        //        NSApp.setActivationPolicy(settingsViewModel.showDockIcon ? .regular : .accessory)
        
        // TODO: remove this line
        //        ImageCache.default.diskStorage.config.expiration = .days(1)
        //        ImageCache.default.clearDiskCache()
        
        xx = self
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        
        bind()
    }
    
    private func bind() {
        Publishers.CombineLatest4(cabinet.$storedEntries,
                                  cabinet.$recentEntries,
                                  settingsViewModel.$collapseHistory,
                                  Publishers.CombineLatest(searchViewModel.$searching,
                                                           NSApp.publisher(for: \.effectiveAppearance)))
        .map({ ($0, $1, $2, $3.0, $3.1) })
        .sink { [weak self] tuple5 in
            Task { @MainActor in
                self?.statusItem?.menu = self?.generateMenu(from: tuple5.0, history: tuple5.1, collapseHistory: tuple5.3)
            }
        }
        .store(in: &cancellables)
        
        NotificationCenter.default.addObserver(forName: .onShortcutKeyDown, object: nil, queue: nil) { [weak self] _ in
            if let button = self?.statusItem?.button {
                button.performClick(nil)
            }
        }
        
        NotificationCenter.default.addObserver(forName: .onOutlineViewRowCount, object: nil, queue: nil) { [unowned self] noti in
            guard let height = noti.object as? CGFloat else { return }
            editPopoverContentSize(height)
        }
        
        NotificationCenter.default.addObserver(forName: .onCellBecomeFirstResponder, object: nil, queue: nil) { [weak self] _ in
            self?.editPopover.behavior = .applicationDefined
        }
        
        NotificationCenter.default.addObserver(forName: .onCellResignFirstResponder, object: nil, queue: nil) { [weak self] _ in
            self?.editPopover.behavior = .transient
        }
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
        if (editPopover.isShown) {
            editPopover.performClose(self)
        } else {
            editPopoverContentSize(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
            DispatchQueue.main.async { [unowned self] in
                self.editPopover.show(relativeTo: .zero, of: self.statusItem!.button!, preferredEdge: .minY)
            }
        }
    }
    
    private func editPopoverContentSize(_ height: CGFloat?) {
        let h = height
        ?? outlineViewHeight
        ?? cabinet.storedEntries
            .filter({ $0.parentId == nil })
            .map({ $0.height })
            .reduce(0, { $0 + $1 })
        outlineViewHeight = h
        self.editPopover.contentSize = CGSize(width: 800, height: (h <= 200 ? 200 : h) + 34)
    }
}

extension AppDelegate: NSPopoverDelegate {
    func popoverDidClose(_ notification: Notification) {
        NotificationCenter.default.post(name: .onEditPopoverClose, object: nil)
    }
}

