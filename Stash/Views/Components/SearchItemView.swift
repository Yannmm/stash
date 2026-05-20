//
//  MenuItemView.swift
//  Stash
//
//  Created by Rayman on 2025/7/21.
//

import SwiftUI

struct _SearchItemView: View {
    let item: SearchItem
    let highlight: Bool
    let onTap: (SearchItem) -> Void
    let query: String
    
    private var usesGlassStyle: Bool {
        if #available(macOS 26, *) { return true }
        return false
    }
    
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
            RoundedRectangle(cornerRadius: 8)
                .fill(highlight ? (usesGlassStyle ? Color.accentColor.opacity(0.15) : Color(NSColor.controlAccentColor)) : .clear)
        )
        .cornerRadius(8)
        .onTapGesture {
            onTap(item)
        }
    }
    
    @ViewBuilder
    private func title() -> some View {
        Text(item.title.condense(matching: query).emphasize(query) { attr in
            attr.foregroundColor = (highlight && !usesGlassStyle) ? .white : .primary
            attr.font = .system(size: 15, weight: .light)
        } highlightStyle: { attr, range in
            attr[range].foregroundColor = (highlight && !usesGlassStyle) ? .white : .theme
            attr[range].font = .system(size: 15, weight: .bold)
        })
        .lineLimit(1)
//        .fixedSize(horizontal: false, vertical: true)
        .truncationMode(.middle)
        .padding(.top, -2)
    }
    
    @ViewBuilder
    private func detail() -> some View {
        Text(item.detail.condense(matching: query, leading: 30, trailing: 30, context: 10).emphasize(query) { attr in
            attr.foregroundColor = (highlight && !usesGlassStyle) ? .white : .secondary
            attr.font = .system(size: 12, weight: .light)
        } highlightStyle: { attr, range in
            attr[range].foregroundColor = (highlight && !usesGlassStyle) ? .white : .theme
            attr[range].font = .system(size: 12, weight: .bold)
        })
        .lineLimit(1)
//        .fixedSize(horizontal: false, vertical: true)
        .truncationMode(.middle)
    }
}
