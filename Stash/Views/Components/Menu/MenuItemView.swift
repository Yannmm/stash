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
    
    private var isCurrentlyHovered: Bool {
        hoveredItem == item.id
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Icon
            SwiftUI.Group {
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
                withAnimation(.easeInOut(duration: 0.1)) {
                    hoveredItem = item.id
                }
            } else {
                withAnimation(.easeInOut(duration: 0.1)) {
                    hoveredItem = nil
                }
            }
        }
        .onTapGesture {
            print("重新 reload（如果是 group）或者前往地址（bookmark）")
            
        }
        .onGeometryChange(for: CGRect.self) { proxy in
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
