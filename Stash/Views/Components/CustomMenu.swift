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
struct _MenuItemView: View {
    let item: MenuItemData
    @State private var isHovered = false
    @Binding var hoveredItem: UUID?
    let onShowSubmenu: (MenuItemData) -> Void
    let onHideSubmenu: (MenuItemData) -> Void
    @State private var timer: Timer?
    
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
                .frame(height: 20)
                .background(
                    Rectangle()
                        .fill(isCurrentlyHovered && item.isEnabled ? 
                            Color(NSColor.controlAccentColor) : 
                            Color.clear)
                )
                .contentShape(Rectangle())
                .onHover { hovering in
                    if hovering && item.isEnabled {
                        // Cancel any pending close timer when hovering over parent item
                        cancelSubmenuTimer()
                        
                        withAnimation(.easeInOut(duration: 0.1)) {
                            hoveredItem = item.id
                        }
                        
                        // Show submenu if item has one
                        if item.hasSubmenu {
                            onShowSubmenu(item)
                        }
                    } else {
                        // When leaving parent item, start a delay before closing submenu
                        if hoveredItem == item.id && item.hasSubmenu {
                            print("Leaving item with submenu: \(item.title), starting timer")
                            startSubmenuCloseTimer()
                        } else if hoveredItem == item.id {
                            print("Leaving item without submenu: \(item.title), clearing hover")
                            withAnimation(.easeInOut(duration: 0.1)) {
                                hoveredItem = nil
                            }
                            onHideSubmenu(item)
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
                .onGeometryChange(for: CGSize.self) { proxy in
                    print("aaa -> \(proxy.frame(in: .global))")
                    if let frame = xx?.statusItem?.button?.window?.convertToScreen(proxy.frame(in: .global)) {
                        print("bbbb -> \(frame)")
                 }
                    
                                return proxy.size
                    
                            } action: {
//                                self.contentHeight = $0.height
                                print("xxxx -> \($0)")
                                // Alternatively you can get the `width` here
                            }

        }
    }
    
    private func cancelSubmenuTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func startSubmenuCloseTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
            // Only close if submenu is not being hovered
//            if !isSubmenuHovered {
//                withAnimation(.easeInOut(duration: 0.1)) {
//                    hovered = nil
//                }
//                hideSubmenu()
//            }
            timer = nil
        }
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
        
        print("panel size -> \(panelSize.height)")
        
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
    @State private var isSubmenuHovered = false
    
    var menuManager: MenuManager { MenuManager.shared }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                _MenuItemView(
                    item: item,
                    hoveredItem: $hovered,
                    onShowSubmenu: { item in
                        guard let items = item.submenu else { return }
                        menuManager.show(items, anchorRect: .zero, source: item)
                    },
                    onHideSubmenu: { item in
                        menuManager.hide(item)
                    }
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
        .frame(minWidth: 180)
        .fixedSize() // Allow content to determine its own size
    }

    private func hideSubmenu() {
//        submenuPanel?.close()
//        submenuPanel = nil
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


struct FramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
