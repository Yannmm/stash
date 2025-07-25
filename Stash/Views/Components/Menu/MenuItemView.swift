//
//  MenuItemView.swift
//  Stash
//
//  Created by Rayman on 2025/7/21.
//

import SwiftUI

struct _MenuItemView: View {
    let item: SearchItem
    @State private var hovering = false
    @State private var frame = CGRect.zero
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Icon
            ViewHelper.icon(item.icon, side: 45)
            // Title and Detail
            VStack(alignment: .leading, spacing: 1) {
                title()
                detail()
            }
            
            Spacer()
        }
        .background(
//            Rectangle()
//                .fill(Color(NSColor.controlAccentColor))
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            if hovering  {
                withAnimation(.easeInOut(duration: 0.1)) {
                    self.hovering = true
                }
            } else {
                withAnimation(.easeInOut(duration: 0.1)) {
                    self.hovering = false
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
    
    @ViewBuilder
    private func title() -> some View {
        Text(item.title)
            .font(.system(size: 13))
            .foregroundColor(hovering ? .white : .primary)
    }
    
    @ViewBuilder
    private func detail() -> some View {
        Text(item.detail)
            .font(.system(size: 11))
            .foregroundColor((hovering ? Color.white.opacity(0.8) : .secondary))
    }
}
