//
//  MenuItemView.swift
//  Stash
//
//  Created by Rayman on 2025/7/21.
//

import SwiftUI

struct _MenuItemView: View {
    let item: MenuItemData
    @State private var isHovered = false
    @State private var frame = CGRect.zero
    @Binding var hoveredItem: UUID?
    let onExpand: (MenuItemData) -> Void
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
                        .foregroundColor(item.enabled ?
                                         (isCurrentlyHovered ? .white : .primary) :
                                .secondary)
                    
                    if let detail = item.detail {
                        Text(detail)
                            .font(.system(size: 11))
                            .foregroundColor(item.enabled ?
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
                            .foregroundColor(item.enabled ?
                                             (isCurrentlyHovered ? Color.white.opacity(0.8) : .secondary) :
                                    .accentColor)
                    }
                    
                    if item.hasSubmenu {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(item.enabled ?
                                             (isCurrentlyHovered ? .white : .secondary) :
                                    .accentColor)
                    }
                }
                .padding(.trailing, 8)
            }
            .frame(height: 20)
            .background(
                Rectangle()
                    .fill(isCurrentlyHovered && item.enabled ?
                          Color(NSColor.controlAccentColor) :
                            Color.clear)
            )
            .contentShape(Rectangle())
            .onHover { hovering in
                if hovering && item.enabled {
                    // Cancel any pending close timer when hovering over parent item
//                    cancelSubmenuTimer()
                    
                    withAnimation(.easeInOut(duration: 0.1)) {
                        hoveredItem = item.id
                    }
                    
                    // Show submenu if item has one
                    if item.hasSubmenu {
                        onExpand(item)
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
//                if item.isEnabled {
//                    if let action = item.action {
//                        action()
//                    }
//                }
            }
            .onGeometryChange(for: CGRect.self) { proxy in
//                print("aaa -> \(proxy.frame(in: .global))")
                // TODO: will the window change
                if let frame = NSApp.windows
                    .first(where: { $0.level == .statusBar })?
                    .convertToScreen(proxy.frame(in: .global)) {
                    return frame
                }
                return .zero
            } action: {
                self.frame = $0
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
