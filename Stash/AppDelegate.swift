//
//  AppDelegate.swift
//  Stash
//
//  Created by Rayman on 2025/2/10.
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate!
    var popover = NSPopover()
    var statusItem: NSStatusItem?
    var dropWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        setupStatusItem()
        createDropWindow()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        let contentView = ContentView().environmentObject(BookmarkManager.shared)
        popover.contentSize = NSSize(width: 300, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "bookmark.fill", accessibilityDescription: nil)
            button.action = #selector(togglePopover)
        }
        
        let menu = NSMenu()
        let k1 = NSMenuItem(title: "History", action: nil, keyEquivalent: "")
        let text = "History"
        let attributedString = NSMutableAttributedString(string: "History")

        // Define the attributes you want to apply
        let boldAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 14),
            .foregroundColor: NSColor.red
        ]
        
        attributedString.addAttributes(boldAttributes, range: (text as NSString).range(of: "Hello"))
        k1.attributedTitle = attributedString
        menu.addItem(k1)
        
        let p = NSMenuItem(title: "Open Settings", action: #selector(openSettings), keyEquivalent: "S")
        let n = NSMenuItem(title: "Secondary Level", action: #selector(togglePopover), keyEquivalent: "P")
        let n1 = NSMenu()
        n1.addItem(n)
        p.submenu = n1
        menu.addItem(p)
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "Q"))
        
        statusItem?.menu = menu
    }
    
    @objc func openSettings() {
        NSApplication.shared.terminate(self)
    }
    
    @objc private func quit() {}
    
    private func createDropWindow() {
        dropWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 400),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        dropWindow?.contentViewController = NSHostingController(rootView: DragAndDropView().environmentObject(BookmarkManager.shared))
        dropWindow?.title = "Drag and Drop1111"
        dropWindow?.isReleasedWhenClosed = false
        dropWindow?.collectionBehavior = [.managed, .fullScreenNone]
    }
    
    func showDropWindow() {
        dropWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: false)
    }
    
    @objc func togglePopover() {
        guard let button = statusItem?.button else { return }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
