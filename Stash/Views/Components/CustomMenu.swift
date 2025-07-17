//
//  CustomMenu.swift
//  Stash
//
//  Created by Assistant on 2025/7/15.
//

import SwiftUI

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
    let isEnabled: Bool
    
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
        self.isEnabled = isEnabled
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
        self.isEnabled = true
    }
    
    static func == (lhs: MenuItemData, rhs: MenuItemData) -> Bool {
        lhs.id == rhs.id
    }
    
    var hasSubmenu: Bool {
        submenu?.isEmpty == false
    }
}

// MARK: - Individual Menu Item View
struct CustomMenuItemView: View {
    let item: MenuItemData
    let level: Int
    @State private var isHovered = false
    @Binding var hoveredItem: UUID?
    let onCancelTimer: () -> Void
    let onStartTimer: () -> Void
    
    private var isCurrentlyHovered: Bool {
        hoveredItem == item.id
    }
    
    var body: some View {
        if item.isSeparator {
            Divider()
                .background(Color(NSColor.separatorColor))
                .padding(.vertical, 2)
        } else {
            HStack(spacing: 0) {
                                    // Icon
                ZStack {
                    if let icon = item.icon {
                        Image(nsImage: icon)
                            .frame(width: 16, height: 16)
                    } else {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 16, height: 16)
                    }
                }
                .frame(width: 24)
                .padding(.leading, 8)
                    
                    // Title and Detail
                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.title)
                            .font(.system(size: 13))
                            .foregroundColor(item.isEnabled ? 
                                (isCurrentlyHovered ? .white : .primary) : 
                                .secondary)
                        
                        if let detail = item.detail {
                            Text(detail)
                                .font(.system(size: 11))
                                .foregroundColor(item.isEnabled ? 
                                    (isCurrentlyHovered ? Color.white.opacity(0.8) : .secondary) : 
                                        .accentColor)
                        }
                    }
                    
                    Spacer()
                    
                    // Key Equivalent or Submenu Arrow
                    HStack(spacing: 4) {
                        if let keyEquivalent = item.keyEquivalent, !keyEquivalent.isEmpty {
                            Text(keyEquivalent)
                                .font(.system(size: 11))
                                .foregroundColor(item.isEnabled ?
                                    (isCurrentlyHovered ? Color.white.opacity(0.8) : .secondary) : 
                                    .accentColor)
                        }
                        
                        if item.hasSubmenu {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(item.isEnabled ? 
                                    (isCurrentlyHovered ? .white : .secondary) : 
                                    .accentColor)
                        }
                    }
                    .padding(.trailing, 8)
                }
                .frame(height: item.detail != nil ? 32 : 20)
                .background(
                    Rectangle()
                        .fill(isCurrentlyHovered && item.isEnabled ? 
                            Color(NSColor.selectedMenuItemColor) : 
                            Color.clear)
                )
                .contentShape(Rectangle())
                .onHover { hovering in
                    if hovering && item.isEnabled {
                        // Cancel any pending close timer when hovering over parent item
                        onCancelTimer()
                        
                        withAnimation(.easeInOut(duration: 0.1)) {
                            hoveredItem = item.id
                        }
                    } else {
                        // When leaving parent item, start a delay before closing submenu
                        if hoveredItem == item.id && item.hasSubmenu {
                            onStartTimer()
                        } else if hoveredItem == item.id {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                hoveredItem = nil
                            }
                        }
                    }
                }
                .onTapGesture {
                    if item.isEnabled {
                        if let action = item.action {
                            action()
                        }
                    }
                }

        }
    }
    

}

// MARK: - Main Menu View
struct CustomMenuView: View {
    let items: [MenuItemData]
    let level: Int
    @State private var hoveredItem: UUID?
    @State private var submenuCloseTimer: Timer?
    @State private var isSubmenuHovered = false
    
    init(items: [MenuItemData], level: Int = 0) {
        self.items = items
        self.level = level
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    CustomMenuItemView(
                        item: item,
                        level: level,
                        hoveredItem: $hoveredItem,
                        onCancelTimer: cancelSubmenuTimer,
                        onStartTimer: startSubmenuCloseTimer
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
            .overlay(alignment: .topLeading) {
                // Submenu positioning
                submenuOverlay(geometry: geometry)
            }
        }
        .frame(minWidth: 180)
        .onDisappear {
            // Clean up timer when view disappears
            submenuCloseTimer?.invalidate()
            submenuCloseTimer = nil
        }
    }
    
    private func cancelSubmenuTimer() {
        submenuCloseTimer?.invalidate()
        submenuCloseTimer = nil
    }
    
    private func startSubmenuCloseTimer() {
        submenuCloseTimer?.invalidate()
        submenuCloseTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
            // Only close if submenu is not being hovered
            if !isSubmenuHovered {
                withAnimation(.easeInOut(duration: 0.1)) {
                    hoveredItem = nil
                }
            }
            submenuCloseTimer = nil
        }
    }
    
    @ViewBuilder
    private func submenuOverlay(geometry: GeometryProxy) -> some View {
        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
            if let submenuItems = item.submenu,
               let hoveredItem = hoveredItem,
               hoveredItem == item.id {
                
                let itemHeight: CGFloat = item.detail != nil ? 32 : 20
                let paddingTop: CGFloat = 4
                let itemVerticalCenter = paddingTop + (CGFloat(index) * itemHeight) + (itemHeight / 2)
                
                                 CustomMenuView(
                     items: submenuItems,
                     level: level + 1
                 )
                 .onHover { hovering in
                     isSubmenuHovered = hovering
                     if hovering {
                         // Cancel close timer when hovering over submenu
                         cancelSubmenuTimer()
                     } else {
                         // Start close timer when leaving submenu
                         startSubmenuCloseTimer()
                     }
                 }
                 .position(
                     x: geometry.size.width + 90, // Position to the right of parent menu
                     y: itemVerticalCenter // Center vertically on the triggering item
                 )
                 .zIndex(Double(level + 1))
            }
        }
    }
}

// MARK: - Menu Builder Helper
extension MenuItemData {
    static func buildMenu(@MenuBuilder _ content: () -> [MenuItemData]) -> [MenuItemData] {
        content()
    }
}

@resultBuilder
struct MenuBuilder {
    static func buildBlock(_ components: MenuItemData...) -> [MenuItemData] {
        components
    }
    
    static func buildArray(_ components: [[MenuItemData]]) -> [MenuItemData] {
        components.flatMap { $0 }
    }
    
    static func buildOptional(_ component: [MenuItemData]?) -> [MenuItemData] {
        component ?? []
    }
    
    static func buildEither(first component: [MenuItemData]) -> [MenuItemData] {
        component
    }
    
    static func buildEither(second component: [MenuItemData]) -> [MenuItemData] {
        component
    }
}

// MARK: - Preview
#if DEBUG
struct CustomMenuView_Previews: PreviewProvider {
    static var previews: some View {
        CustomMenuView(items: sampleMenuItems)
            .frame(width: 300, height: 400)
            .background(Color.gray.opacity(0.1))
    }
    
    static var sampleMenuItems: [MenuItemData] = [
        MenuItemData(
            title: "Recently Visited",
            icon: NSImage(systemSymbolName: "clock.fill", accessibilityDescription: nil),
            submenu: [
                MenuItemData(title: "Google", detail: "https://google.com", action: {}),
                MenuItemData(title: "GitHub", detail: "https://github.com", action: {}),
                MenuItemData.separator,
                MenuItemData(title: "Stack Overflow", detail: "https://stackoverflow.com", action: {})
            ]
        ),
        MenuItemData.separator,
        MenuItemData(
            title: "Bookmarks",
            icon: NSImage(systemSymbolName: "book.fill", accessibilityDescription: nil),
            submenu: [
                MenuItemData(title: "Development", submenu: [
                    MenuItemData(title: "SwiftUI", action: {}),
                    MenuItemData(title: "UIKit", action: {}),
                    MenuItemData(title: "AppKit", action: {})
                ]),
                MenuItemData(title: "Design", action: {}),
                MenuItemData(title: "Documentation", action: {})
            ]
        ),
        MenuItemData(
            title: "Create New Bookmark",
            icon: NSImage(systemSymbolName: "link.badge.plus", accessibilityDescription: nil),
            keyEquivalent: "C",
            action: {}
        ),
        MenuItemData(
            title: "Import from File",
            icon: NSImage(systemSymbolName: "square.and.arrow.down", accessibilityDescription: nil),
            keyEquivalent: "I",
            action: {}
        ),
        MenuItemData.separator,
        MenuItemData(
            title: "Manage",
            keyEquivalent: "M",
            action: {}
        ),
        MenuItemData(
            title: "Settings",
            keyEquivalent: "S",
            action: {}
        ),
        MenuItemData(
            title: "Quit",
            action: {}
        )
    ]
}
#endif 
