//
//  MenuItemView.swift
//  Stash
//
//  Created by Rayman on 2025/7/21.
//

import SwiftUI

struct _SearchItemView: View {
    let item: SearchItem
    @State private var hovering = false
    @State private var frame = CGRect.zero
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ViewHelper.icon(item.icon, side: 30)
            VStack(alignment: .leading, spacing: 0) {
                title()
                detail()
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            Rectangle()
                .fill(hovering ? Color(NSColor.controlAccentColor) : .clear)
        )
        .cornerRadius(6)
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
            .font(.system(size: 15, weight: .regular))
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, -2)
            .foregroundColor(hovering ? .white : .primary)
    }
    
    @ViewBuilder
    private func detail() -> some View {
        Text(item.detail)
            .font(.system(size: 12, weight: .light))
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .foregroundColor((hovering ? .white : .secondary))
    }
}
