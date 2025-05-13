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
    
    var statusItem: NSStatusItem?
    var dropWindow: NSWindow?
    
    private lazy var editPopover: NSPopover = {
        let p = NSPopover()
        let contentView = ContentView().environmentObject(cabinet)
        p.behavior = .transient
        p.contentViewController = NSHostingController(rootView: contentView)
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
    
    private var outlineViewRowCount: Int?
    
    private var settingsWindow: NSWindow?
    
    func applicationWillFinishLaunching(_ notification: Notification) {
//        NSApp.setActivationPolicy(settingsViewModel.showDockIcon ? .regular : .accessory)
        hotKeyMananger.register(shortcut: settingsViewModel.shortcut)
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        
        if let token = FileManager.default.ubiquityIdentityToken {
            print("iCloud identity token: \(token)")
        } else {
            print("❌ No iCloud identity — user not signed in or entitlement missing")
        }
        
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
            self.editPopover.contentSize = self.editPopoverContentSize(count)
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
            let count = outlineViewRowCount ?? cabinet.storedEntries.filter({ $0.parentId == nil }).count
            editPopover.contentSize = editPopoverContentSize(count)
            editPopover.show(relativeTo: statusItem!.button!.bounds, of: statusItem!.button!, preferredEdge: .minY)
            editPopover.contentViewController?.view.window?.makeKey()
        }
    }
    
    private func editPopoverContentSize(_ entryCount: Int) -> CGSize {
        CGSize(width: 800, height: (entryCount < 3 ? 3 : entryCount) * 49 + 34)
    }
}
