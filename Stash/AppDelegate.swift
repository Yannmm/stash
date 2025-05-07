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

class AppDelegate: NSObject, NSApplicationDelegate {
    var popover = NSPopover()
    var statusItem: NSStatusItem?
    var dropWindow: NSWindow?
    
    private lazy var settingsViewModel: SettingsViewModel = {
        let viewModel = SettingsViewModel(hotKeyManager: hotKeyMananger, cabinet: cabinet)
        return viewModel
    }()    
    var cabinet: OkamuraCabinet { OkamuraCabinet.shared }
    
    var hotKeyMananger: HotKeyManager { HotKeyManager.shared }
    
    private let dominator = Dominator()
    
    private var cancellables = Set<AnyCancellable>()
    
    private var outlineViewRowCount: Int?
    
    private var settingsWindow: NSWindow?
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(settingsViewModel.showDockIcon ? .regular : .accessory)
        hotKeyMananger.register(shortcut: settingsViewModel.shortcut)
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
            guard let count = noti.object as? Int else { return }
            self.outlineViewRowCount = count
            self.popover.contentSize = self.editPopoverContentSize(count)
        }
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        let contentView = ContentView().environmentObject(cabinet)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        
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
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
    
    @objc private func quit() {}
    
    @objc func togglePopover() {
        if (popover.isShown) {
            popover.performClose(self)
        } else {
            let count = outlineViewRowCount ?? cabinet.storedEntries.filter({ $0.parentId == nil }).count
            popover.contentSize = editPopoverContentSize(count)
            popover.show(relativeTo: statusItem!.button!.bounds, of: statusItem!.button!, preferredEdge: .minY)
        }
    }
    
    private func editPopoverContentSize(_ entryCount: Int) -> CGSize {
        CGSize(width: 800, height: (entryCount < 3 ? 3 : entryCount) * 49 + 34)
    }
}
