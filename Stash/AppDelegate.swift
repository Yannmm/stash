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
    
    private var cancellables = Set<AnyCancellable>()
    
    private var settingsWindow: NSWindow?
    
    private var hotxxx: HotKey?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        
        HotKeyManager.shared.register(shortcut: settingsViewModel.shortcut)
        
        Publishers.CombineLatest3(cabinet.$storedEntries, cabinet.$recentEntries, settingsViewModel.$collapseHistory)
            .sink { [weak self] tuple3 in
                self?.statusItem?.menu = self?.generateMenu(from: tuple3.0, history: tuple3.1, collapseHistory: tuple3.2)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.addObserver(forName: .onShortcutKeyDown, object: nil, queue: nil) { [weak self] _ in
            if let button = self?.statusItem?.button {
                button.performClick(nil)
            }
        }
        
        hotKeyMananger.register(shortcut: settingsViewModel.shortcut)
    }
    
    let dominator = Dominator()
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        let contentView = ContentView().environmentObject(cabinet)
        popover.contentSize = NSSize(width: 600, height: 400)
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
        
//        let panel = NSOpenPanel()
//        panel.canChooseFiles = true
//        panel.canChooseDirectories = false
//        panel.allowsMultipleSelection = false
//
//        if panel.runModal() == .OK, let url = panel.url {
//            // Now you can access the file
//            do {
//                let content = try String(contentsOf: url)
//                do {
//                    try dominator.test1(content)
//                } catch {
//                    print(error)
//                }
//            } catch {
//                print("Error reading file: \(error)")
//            }
//        }
    }
    
    @objc private func quit() {}
    
    func showDropWindow() {
        dropWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: false)
    }
    
    @objc func togglePopover() {
        if (popover.isShown) {
            popover.performClose(self)
        } else {
            popover.show(relativeTo: statusItem!.button!.bounds, of: statusItem!.button!, preferredEdge: .minY)
        }
    }
}
