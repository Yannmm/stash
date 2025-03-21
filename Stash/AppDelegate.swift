//
//  AppDelegate.swift
//  Stash
//
//  Created by Rayman on 2025/2/10.
//

import AppKit
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate!
    var popover = NSPopover()
    var statusItem: NSStatusItem?
    var dropWindow: NSWindow?
    
    var cabinet: OkamuraCabinet {
        OkamuraCabinet.shared
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        setupStatusItem()
        createDropWindow()
        
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
            button.image = NSImage(systemSymbolName: "bookmark.fill", accessibilityDescription: nil)
            //            button.action = #selector(togglePopover)
        }
        
        //        let menu = NSMenu()
        //        let k1 = NSMenuItem(title: "History", action: nil, keyEquivalent: "")
        //        let text = "History"
        //        let attributedString = NSMutableAttributedString(string: "History")
        //
        //        // Define the attributes you want to apply
        //        let boldAttributes: [NSAttributedString.Key: Any] = [
        //            .font: NSFont.boldSystemFont(ofSize: 14),
        //            .foregroundColor: NSColor.red
        //        ]
        //
        //        attributedString.addAttributes(boldAttributes, range: (text as NSString).range(of: "Hello"))
        //        k1.attributedTitle = attributedString
        //        menu.addItem(k1)
        //
        //        let p = NSMenuItem(title: "Open Settings", action: #selector(openSettings), keyEquivalent: "S")
        //        let n = NSMenuItem(title: "Secondary Level", action: #selector(togglePopover), keyEquivalent: "P")
        //        let n1 = NSMenu()
        //        n1.addItem(n)
        //        p.submenu = n1
        //        menu.addItem(p)
        //        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "Q"))
        //        statusItem?.menu = menu
        
    }
    
    @objc func openSettings() {
        NSApplication.shared.terminate(self)
    }
    
    //    func openNewWindow() {
    //        let window = NSWindow(
    //            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
    //            styleMask: [.titled, .closable, .resizable],
    //            backing: .buffered,
    //            defer: false
    //        )
    //        window.center()
    //        window.setFrameAutosaveName("NewWindow")
    //        window.contentView = NSHostingView(rootView: ContentView())
    //
    //        let windowController = NSWindowController(window: window)
    ////        windowControllers.append(windowController) // Keep a reference so it's not deallocated
    //        windowController.showWindow(nil)
    //    }
    
    @objc private func quit() {}
    
    private func createDropWindow() {
//        dropWindow = NSWindow(
//            contentRect: NSRect(x: 0, y: 0, width: 400, height: 400),
//            styleMask: [.titled, .closable, .miniaturizable, .resizable],
//            backing: .buffered,
//            defer: false
//        )
//        dropWindow?.contentViewController = NSHostingController(rootView: DragAndDropView().environmentObject(cabinet))
//        dropWindow?.title = "Drag and Drop1111"
//        dropWindow?.isReleasedWhenClosed = false
//        dropWindow?.collectionBehavior = [.managed, .fullScreenNone]
    }
    
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
}
