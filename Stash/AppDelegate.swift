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
    
    var statusItem: NSStatusItem?
    var dropWindow: NSWindow?
    
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
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        
        bind()
    }
    
    private func bind() {
        Publishers.CombineLatest3(cabinet.$storedEntries, cabinet.$recentEntries, settingsViewModel.$collapseHistory)
            .sink { [weak self] tuple3 in
                Task { @MainActor in
                    self?.statusItem?.menu = self?.generateMenu(from: tuple3.0, history: tuple3.1, collapseHistory: tuple3.2)
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
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "square.stack.3d.up.fill", accessibilityDescription: nil)
            
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ","))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
            
            statusItem?.menu = menu
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
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
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

