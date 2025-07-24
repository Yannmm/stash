//
//  CustomMenu.swift
//  Stash
//
//  Created by Assistant on 2025/7/15.
//

import SwiftUI
import AppKit

// MARK: - Menu Item Data Structure
struct SearchItem: Identifiable, Equatable {
    let id: UUID
    let title: String
    let detail: String
    let icon: Icon
    
    static func == (lhs: SearchItem, rhs: SearchItem) -> Bool {
        lhs.id == rhs.id
    }
}

class Menu {
    let anchorRect: NSRect
    let content: AnyView
    init(at anchorRect: NSRect, items: [SearchItem]) {
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
    let items: [SearchItem]
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
    
    private var stack: [(SearchItem?, Menu)] = []
    
    func show(_ items: [SearchItem], anchorRect: NSRect, source: SearchItem?) {
        let menu = Menu(at: anchorRect, items: items)
        
        menu.show()
        
        stack.insert((source, menu), at: 0)
    }
    
    func hide(_ item: SearchItem) {
        let x = stack.remove(at: 0)
        x.1.close()
    }
}
