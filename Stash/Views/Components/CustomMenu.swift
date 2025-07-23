//
//  CustomMenu.swift
//  Stash
//
//  Created by Assistant on 2025/7/15.
//

import SwiftUI
import AppKit

// MARK: - Menu Item Data Structure
struct MenuItemData: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let detail: String?
    let icon: NSImage?
    let keyEquivalent: String?
    let action: (() -> Void)?
    let submenu: [MenuItemData]?
    let isSeparator: Bool
    let enabled: Bool
    
    init(
        title: String,
        detail: String? = nil,
        icon: NSImage? = nil,
        keyEquivalent: String? = nil,
        action: (() -> Void)? = nil,
        submenu: [MenuItemData]? = nil,
        isEnabled: Bool = true
    ) {
        self.title = title
        self.detail = detail
        self.icon = icon
        self.keyEquivalent = keyEquivalent
        self.action = action
        self.submenu = submenu
        self.isSeparator = false
        self.enabled = isEnabled
    }
    
    // Separator initializer
    static var separator: MenuItemData {
        MenuItemData(title: "", isSeparator: true)
    }
    
    private init(title: String, isSeparator: Bool) {
        self.title = title
        self.detail = nil
        self.icon = nil
        self.keyEquivalent = nil
        self.action = nil
        self.submenu = nil
        self.isSeparator = isSeparator
        self.enabled = true
    }
    
    static func == (lhs: MenuItemData, rhs: MenuItemData) -> Bool {
        lhs.id == rhs.id
    }
    
    var hasSubmenu: Bool {
        submenu?.isEmpty == false
    }
}

class Menu {
    let anchorRect: NSRect
    let content: AnyView
    init(at anchorRect: NSRect, items: [MenuItemData]) {
        self.anchorRect = anchorRect
        self.content = AnyView(_Menu(items: items))
    }
    
    private var _panel: NSPanel!
    
    func show() {
        close()
        
        let hosting = NSHostingController(rootView: content)
        hosting.view.frame = CGRect(origin: .zero, size: hosting.view.intrinsicContentSize)
        
        _panel = NSPanel(
            contentRect: hosting.view.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        _panel.level = .statusBar
        _panel.isOpaque = true
        _panel.backgroundColor = NSColor.clear
        _panel.hasShadow = true
        _panel.worksWhenModal = true
        _panel.becomesKeyOnlyIfNeeded = false
        _panel.acceptsMouseMovedEvents = true
        _panel.contentViewController = hosting
        
        let panelSize = hosting.view.intrinsicContentSize // your panel's size
        
        // Position the panel below the status item
        let point = CGPoint(
            x: anchorRect.midX - panelSize.width / 2,
            y: anchorRect.minY - panelSize.height - 5 // 5pt gap below status item
        )
        
        _panel.setFrameOrigin(point)
        _panel.orderFront(nil)
        // TODO: release nspanel
    }
    
    func close() {
        _panel?.close()
        _panel = nil
    }
}

// Menu content
struct _Menu: View {
    let items: [MenuItemData]
    @State private var hovered: UUID?
    @State private var hovering = false
    
    var menuManager: MenuManager { MenuManager.shared }
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                _MenuItemView(
                    item: item,
                    hoveredItem: $hovered,
                )
            }
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(
                    color: .black.opacity(0.25),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(NSColor.separatorColor).opacity(0.3), lineWidth: 0.5)
        )
//        .frame(minWidth: 180)
//        .fixedSize() // Allow content to determine its own size
//        .onHover { hovering in
//            self.hovering = hovering
//            print("menu hovering state: \(self.hovering)")
//        }
    }
}

class MenuManager {
    static let shared = MenuManager()
    
    private var stack: [(MenuItemData?, Menu)] = []
    
    func show(_ items: [MenuItemData], anchorRect: NSRect, source: MenuItemData?) {
        let menu = Menu(at: anchorRect, items: items)
        
        menu.show()
        
        stack.insert((source, menu), at: 0)
    }
    
    func hide(_ item: MenuItemData) {
        let x = stack.remove(at: 0)
        x.1.close()
    }
}
