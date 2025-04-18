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
    static var shared: AppDelegate!
    var popover = NSPopover()
    var statusItem: NSStatusItem?
    var dropWindow: NSWindow?
    
    var cabinet: OkamuraCabinet {
        OkamuraCabinet.shared
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    let hotKey = HotKey(key: .r, modifiers: [.command, .option])
    
    private var settingsWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        setupStatusItem()
        setupHotKey()
        
        cabinet.$entries
            .sink { [weak self] entries in
                self?.statusItem?.menu = self?.generateMenu(from: entries)
            }
            .store(in: &cancellables)
    }
    
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
    
    private func setupHotKey() {
        hotKey.keyDownHandler = { [weak self] in
            if let button = self?.statusItem?.button {
                button.performClick(nil)
            }
        }
    }
    
    private func setupSettingsWindow() {
        let hostingView = NSHostingView(rootView: SettingsView())
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
        settingsWindow?.orderFrontRegardless()
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
    
    @objc func deleteAll() {
        cabinet.removeAll()
    }
    
    @objc func export() {
        OkamuraCabinet.shared.export()
    }
    
    @objc func `import`() {
        OkamuraCabinet.shared.import()
    }
}
