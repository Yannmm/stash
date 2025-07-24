//
//  MenuItemView.swift
//  Stash
//
//  Created by Rayman on 2025/7/21.
//

import SwiftUI

struct _MenuItemView: View {
    let item: SearchItem
    @State private var isHovered = false
    @State private var frame = CGRect.zero
    @Binding var hoveredItem: UUID?
    
    private var isCurrentlyHovered: Bool {
        hoveredItem == item.id
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Icon
            Image(systemName: "star")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 45, height: 45)
                .foregroundStyle(Color.theme)
            
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
        }
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
