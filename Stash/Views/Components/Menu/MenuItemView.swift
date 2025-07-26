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
        HStack(alignment: .top, spacing: 12) {
            ViewHelper.icon(item.icon, side: 35)
            VStack(alignment: .leading, spacing: 2) {
                title()
                detail()
            }
            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 12)
        .background(
            Rectangle()
                .fill(hovering ? Color(NSColor.controlAccentColor) : .clear)
        )
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
            .font(.system(size: 16, weight: .regular))
            .foregroundColor(hovering ? .white : .primary)
    }
    
    @ViewBuilder
    private func detail() -> some View {
        Text(item.detail)
            .font(.system(size: 13, weight: .light))
            .foregroundColor((hovering ? .white : .secondary))
    }
}
