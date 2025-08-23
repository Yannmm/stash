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
    // Not used
    @State private var frame = CGRect.zero
    @Binding var searchText: String
    
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
                .fill(highlight ? Color(NSColor.controlAccentColor) : .clear)
        )
        .cornerRadius(6)
        .onTapGesture {
            onTap(item)
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
        Text(emphasize(item.title) { attr in
            attr.foregroundColor = highlight ? .white : .primary
            attr.font = .system(size: 15, weight: .light)
        } highlightStyle: { attr, range in
            attr[range].foregroundColor = highlight ? .white : .theme
            attr[range].font = .system(size: 15, weight: .bold)
        })
        .lineLimit(nil)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, -2)
    }
    
    @ViewBuilder
    private func detail() -> some View {
        Text(emphasize(item.detail) { attr in
            attr.foregroundColor = highlight ? .white : .secondary
            attr.font = .system(size: 12, weight: .light)
        } highlightStyle: { attr, range in
            attr[range].foregroundColor = highlight ? .white : .theme
            attr[range].font = .system(size: 12, weight: .bold)
        })
        .lineLimit(nil)
        .fixedSize(horizontal: false, vertical: true)
    }
    
    private func emphasize(_ base: String, baseStyle: (inout AttributedString) -> Void, highlightStyle: (inout AttributedString, Range<AttributedString.Index>) -> Void) -> AttributedString {
        var attr = AttributedString(base)
        baseStyle(&attr)
        
        let ranges = base.lowercased().ranges(of: searchText.lowercased())
        guard ranges.count > 0 else { return attr }
        ranges.forEach { r in
            let rr = NSRange(r, in: base)
            if let range = Range(rr, in: attr) {
                highlightStyle(&attr, range)
            }
        }
        return attr
    }
}
