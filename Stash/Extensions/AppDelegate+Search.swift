//
//  AppDelegate+Search.swift
//  Stash
//
//  Created by Yan Meng on 2025/7/17.
//

import AppKit
import SwiftUI

enum Constant1 {
    static var demoMenuItems: [SearchItem] {
        [
            SearchItem(
                title: "Recently Visited",
                icon: NSImage(systemSymbolName: "clock.fill", accessibilityDescription: nil),
                submenu: [
                    SearchItem(
                        title: "Google",
                        detail: "https://google.com",
                        icon: NSImage(systemSymbolName: "globe", accessibilityDescription: nil),
                        action: { print("Opening Google") }
                    ),
                    SearchItem(
                        title: "GitHub",
                        detail: "https://github.com",
                        icon: NSImage(systemSymbolName: "globe", accessibilityDescription: nil),
                        action: { print("Opening GitHub") }
                    ),
                    SearchItem.separator,
                    SearchItem(
                        title: "Stack Overflow",
                        detail: "https://stackoverflow.com",
                        icon: NSImage(systemSymbolName: "globe", accessibilityDescription: nil),
                        action: { print("Opening Stack Overflow") }
                    )
                ]
            ),
            SearchItem.separator,
            SearchItem(
                title: "Development",
                icon: NSImage(systemSymbolName: "folder.fill", accessibilityDescription: nil),
                submenu: [
                    SearchItem(
                        title: "iOS Development",
                        icon: NSImage(systemSymbolName: "iphone", accessibilityDescription: nil),
                        submenu: [
                            SearchItem(title: "SwiftUI", action: { print("SwiftUI selected") }),
                            SearchItem(title: "UIKit", action: { print("UIKit selected") }),
                            SearchItem(title: "Combine", action: { print("Combine selected") })
                        ]
                    ),
                    SearchItem(
                        title: "macOS Development",
                        icon: NSImage(systemSymbolName: "desktopcomputer", accessibilityDescription: nil),
                        submenu: [
                            SearchItem(title: "AppKit", action: { print("AppKit selected") }),
                            SearchItem(title: "SwiftUI for Mac", action: { print("SwiftUI for Mac selected") })
                        ]
                    ),
                    SearchItem.separator,
                    SearchItem(
                        title: "Web Development",
                        icon: NSImage(systemSymbolName: "globe", accessibilityDescription: nil),
                        action: { print("Web Development selected") }
                    )
                ]
            ),
            SearchItem(
                title: "Design Resources",
                icon: NSImage(systemSymbolName: "paintbrush.fill", accessibilityDescription: nil),
                submenu: [
                    SearchItem(title: "Figma", action: { print("Figma selected") }),
                    SearchItem(title: "Sketch", action: { print("Sketch selected") }),
                    SearchItem(title: "Adobe XD", action: { print("Adobe XD selected") })
                ]
            ),
            SearchItem.separator,
            SearchItem(
                title: "Create New Bookmark",
                icon: NSImage(systemSymbolName: "link.badge.plus", accessibilityDescription: nil),
                keyEquivalent: "C",
                action: { print("Create bookmark action") }
            ),
            SearchItem(
                title: "Import from File",
                icon: NSImage(systemSymbolName: "square.and.arrow.down", accessibilityDescription: nil),
                keyEquivalent: "I",
                action: { print("Import action") }
            ),
            SearchItem.separator,
            SearchItem(
                title: "Search",
                icon: NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: nil),
                action: { print("Search action") }
            ),
            SearchItem(
                title: "Manage",
                icon: NSImage(systemSymbolName: "slider.horizontal.3", accessibilityDescription: nil),
                keyEquivalent: "M",
                action: { print("Manage action") }
            ),
            SearchItem(
                title: "Settings",
                icon: NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil),
                keyEquivalent: "S",
                action: { print("Settings action") }
            ),
            SearchItem(
                title: "Disabled Item",
                icon: NSImage(systemSymbolName: "xmark.circle", accessibilityDescription: nil),
                isEnabled: false
            ),
            SearchItem.separator,
            SearchItem(
                title: "Quit",
                icon: NSImage(systemSymbolName: "power", accessibilityDescription: nil),
                action: { print("Quit action") }
            )
        ]
    }
}

extension AppDelegate {
    @objc func search() {
        MenuManager.shared.show(Constant1.demoMenuItems, anchorRect: statusItemButtonFrame, source: nil)
    }
    
    private var statusItemButtonFrame: NSRect {
        if let button = statusItem?.button,
           let frame = button.window?.convertToScreen(button.convert(button.bounds, to: nil)) {
            return frame
        }
        return .zero
    }
}
