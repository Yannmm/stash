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

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "star.circle.fill", accessibilityDescription: "Menu Bar App")
            button.action = #selector(showMenu(_:))
        }

        popover = NSPopover()
        popover?.contentViewController = NSHostingController(rootView: ContentView())
        popover?.behavior = .transient
    }

    @objc func showMenu(_ sender: AnyObject?) {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "Option 1", action: #selector(menuItemClicked(_:)), keyEquivalent: "1"))
        menu.addItem(NSMenuItem(title: "Option 2", action: #selector(showPopover(_:)), keyEquivalent: "2"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil) // Show the menu
    }

    @objc func menuItemClicked(_ sender: NSMenuItem) {
        print("\(sender.title) clicked")
    }

    @objc func showPopover(_ sender: AnyObject?) {
        if let button = statusItem?.button {
            if popover?.isShown == true {
                popover?.performClose(sender)
            } else {
                popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}

