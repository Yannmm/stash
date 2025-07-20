//
//  AppDelegate+Search.swift
//  Stash
//
//  Created by Yan Meng on 2025/7/17.
//

import AppKit
import SwiftUI

enum Constant1 {
    static var demoMenuItems: [MenuItemData] {
        [
            MenuItemData(
                title: "Recently Visited",
                icon: NSImage(systemSymbolName: "clock.fill", accessibilityDescription: nil),
                submenu: [
                    MenuItemData(
                        title: "Google",
                        detail: "https://google.com",
                        icon: NSImage(systemSymbolName: "globe", accessibilityDescription: nil),
                        action: { print("Opening Google") }
                    ),
                    MenuItemData(
                        title: "GitHub",
                        detail: "https://github.com",
                        icon: NSImage(systemSymbolName: "globe", accessibilityDescription: nil),
                        action: { print("Opening GitHub") }
                    ),
                    MenuItemData.separator,
                    MenuItemData(
                        title: "Stack Overflow",
                        detail: "https://stackoverflow.com",
                        icon: NSImage(systemSymbolName: "globe", accessibilityDescription: nil),
                        action: { print("Opening Stack Overflow") }
                    )
                ]
            ),
            MenuItemData.separator,
            MenuItemData(
                title: "Development",
                icon: NSImage(systemSymbolName: "folder.fill", accessibilityDescription: nil),
                submenu: [
                    MenuItemData(
                        title: "iOS Development",
                        icon: NSImage(systemSymbolName: "iphone", accessibilityDescription: nil),
                        submenu: [
                            MenuItemData(title: "SwiftUI", action: { print("SwiftUI selected") }),
                            MenuItemData(title: "UIKit", action: { print("UIKit selected") }),
                            MenuItemData(title: "Combine", action: { print("Combine selected") })
                        ]
                    ),
                    MenuItemData(
                        title: "macOS Development",
                        icon: NSImage(systemSymbolName: "desktopcomputer", accessibilityDescription: nil),
                        submenu: [
                            MenuItemData(title: "AppKit", action: { print("AppKit selected") }),
                            MenuItemData(title: "SwiftUI for Mac", action: { print("SwiftUI for Mac selected") })
                        ]
                    ),
                    MenuItemData.separator,
                    MenuItemData(
                        title: "Web Development",
                        icon: NSImage(systemSymbolName: "globe", accessibilityDescription: nil),
                        action: { print("Web Development selected") }
                    )
                ]
            ),
            MenuItemData(
                title: "Design Resources",
                icon: NSImage(systemSymbolName: "paintbrush.fill", accessibilityDescription: nil),
                submenu: [
                    MenuItemData(title: "Figma", action: { print("Figma selected") }),
                    MenuItemData(title: "Sketch", action: { print("Sketch selected") }),
                    MenuItemData(title: "Adobe XD", action: { print("Adobe XD selected") })
                ]
            ),
            MenuItemData.separator,
            MenuItemData(
                title: "Create New Bookmark",
                icon: NSImage(systemSymbolName: "link.badge.plus", accessibilityDescription: nil),
                keyEquivalent: "C",
                action: { print("Create bookmark action") }
            ),
            MenuItemData(
                title: "Import from File",
                icon: NSImage(systemSymbolName: "square.and.arrow.down", accessibilityDescription: nil),
                keyEquivalent: "I",
                action: { print("Import action") }
            ),
            MenuItemData.separator,
            MenuItemData(
                title: "Search",
                icon: NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: nil),
                action: { print("Search action") }
            ),
            MenuItemData(
                title: "Manage",
                icon: NSImage(systemSymbolName: "slider.horizontal.3", accessibilityDescription: nil),
                keyEquivalent: "M",
                action: { print("Manage action") }
            ),
            MenuItemData(
                title: "Settings",
                icon: NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil),
                keyEquivalent: "S",
                action: { print("Settings action") }
            ),
            MenuItemData(
                title: "Disabled Item",
                icon: NSImage(systemSymbolName: "xmark.circle", accessibilityDescription: nil),
                isEnabled: false
            ),
            MenuItemData.separator,
            MenuItemData(
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
