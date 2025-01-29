//
//  StashApp.swift
//  stash
//
//  Created by Yan Meng on 2025/1/26.
//

import SwiftUI
import SwiftData

// @main
// struct StashApp: App {
//     var sharedModelContainer: ModelContainer = {
//         let schema = Schema([
//             Item.self,
//         ])
//         let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

//         do {
//             return try ModelContainer(for: schema, configurations: [modelConfiguration])
//         } catch {
//             fatalError("Could not create ModelContainer: \(error)")
//         }
//     }()

//     var body: some Scene {
//         WindowGroup {
//             ContentView()
//         }
//         .modelContainer(sharedModelContainer)
//     }
// }

import SwiftUI

@main
struct StashApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

// MARK: - App Delegate
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
        
        let contentView = BookmarkListView().environmentObject(BookmarkManager.shared)
        popover.contentSize = NSSize(width: 300, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "bookmark.fill", accessibilityDescription: nil)
            button.action = #selector(togglePopover)
        }
    }
    
    private func createDropWindow() {
        dropWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 400),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        dropWindow?.contentViewController = NSHostingController(rootView: DropWindowView().environmentObject(BookmarkManager.shared))
        dropWindow?.title = "Drag and Drop"
        dropWindow?.isReleasedWhenClosed = false
        dropWindow?.collectionBehavior = [.managed, .fullScreenNone]
    }
    
    func showDropWindow() {
        dropWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
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
