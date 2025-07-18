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
//        setupSearchPanel()
        let point = NSEvent.mouseLocation
                    rootPanel.showSubmenu(at: point) {
//                        SubmenuContent(items: items, parentScreenPosition: point) { [self] item, submenuPoint in
//                            if let children = item.children {
//                                self.submenuPanel.showSubmenu(at: submenuPoint) {
//                                    SubmenuContent(items: children, parentScreenPosition: submenuPoint) { _, _ in }
//                                }
//                            } else {
//                                self.submenuPanel.close()
//                            }
//                        }
                        
                        CustomMenuView(items: Constant1.demoMenuItems)
                            .frame(width: 300, height: 2000)
                    }
    }
}

struct MenuItem: Identifiable {
    let id = UUID()
    let title: String
    let children: [MenuItem]?
}


struct SubmenuContent: View {
    let items: [MenuItem]
    let parentScreenPosition: CGPoint
    var onOpenSubmenu: (_ item: MenuItem, _ globalPosition: CGPoint) -> Void

    @State private var hoveredItemID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(items) { item in
                HStack {
                    Text(item.title)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if item.children != nil {
                        Image(systemName: "chevron.right")
                            .padding(.trailing, 8)
                    }
                }
                .background(hoveredItemID == item.id ? Color.gray.opacity(0.2) : Color.clear)
                .onHover { hovering in
                    if hovering {
                        hoveredItemID = item.id

                        // Convert local position to global screen coordinates
                        DispatchQueue.main.async {
                            let mouse = NSEvent.mouseLocation
                            onOpenSubmenu(item, mouse)
                        }
                    } else if hoveredItemID == item.id {
                        hoveredItemID = nil
                    }
                }
            }
        }
        .background(Color.white)
        .frame(width: 200)
    }
}

class SubmenuPanelController {
    var panel: NSPanel!

    func showSubmenu<Content: View>(at point: CGPoint, @ViewBuilder content: () -> Content,) {
        if let panel = panel {
            panel.close()
        }

        let hosting = NSHostingController(rootView: content())
        hosting.view.frame = CGRect(origin: .zero, size: hosting.view.intrinsicContentSize)
        
        panel = NSPanel(
            contentRect: hosting.view.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.level = .statusBar
        panel.isOpaque = true
        panel.backgroundColor = NSColor.clear
        panel.hasShadow = true
        panel.worksWhenModal = true
        panel.becomesKeyOnlyIfNeeded = false
        panel.acceptsMouseMovedEvents = true
        
        panel.contentViewController = hosting
        
        let screenHeight = NSScreen.main?.frame.height ?? 0
        let flippedY = screenHeight - point.y
        panel.setFrameTopLeftPoint(NSPoint(x: point.x, y: flippedY))
        panel.orderFront(nil)

//        let panel = NSPanel(
//            contentRect: hosting.view.frame,
//            styleMask: [.nonactivatingPanel, .borderless],
//            backing: .buffered,
//            defer: false
//        )
//
//        panel.isFloatingPanel = true
//        panel.hidesOnDeactivate = true
//        panel.level = .floating
//        panel.hasShadow = true
//        panel.contentView = hosting.view
//        panel.becomesKeyOnlyIfNeeded = true
//        panel.isReleasedWhenClosed = false
//
//        self.panel = panel
//
//        let screenHeight = NSScreen.main?.frame.height ?? 0
//        let flippedY = screenHeight - point.y
//        panel.setFrameTopLeftPoint(NSPoint(x: point.x, y: flippedY))

//        panel.makeKeyAndOrderFront(nil)panel.orderFront(nil)
        
//        let panel = NSPanel(
//            contentRect: hosting.view.frame,
//            styleMask: [.borderless, .nonactivatingPanel],
//            backing: .buffered,
//            defer: false
//        )
//
//        // Configure the panel for menu-like behavior
//        panel.isFloatingPanel = true
//        panel.level = .statusBar   // Ensures it's above normal windows
//        panel.hidesOnDeactivate = true
//        panel.hasShadow = true
//        panel.becomesKeyOnlyIfNeeded = false // <- Key part
//        panel.ignoresMouseEvents = false
//        panel.acceptsMouseMovedEvents = true
//        panel.isOpaque = false
//        panel.backgroundColor = .clear
//        panel.collectionBehavior = [
//            .canJoinAllSpaces,
//            .transient,
//            .moveToActiveSpace
//        ]
//
//        // Embed SwiftUI view
//        panel.contentView = hosting.view
//        panel.orderFront(nil)
    }

    func close() {
        panel?.close()
        panel = nil
    }
}
