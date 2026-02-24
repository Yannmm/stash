//
//  HashtagField.swift
//  Stash
//
//  Created by Rayman on 2026/2/24.
//

import SwiftUI

struct HashtagField: View {
    @FocusState private var focused: Bool
    
    @State private var title: String?
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "tag")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: NSImage.Constant.side1, height: NSImage.Constant.side1)
//                .foregroundStyle(Color.theme)
            Divider()
            HashtagTextField(text: $title ?? "", focused: focused)
                .font(NSFont.systemFont(ofSize: NSFont.systemFontSize))
                .focused($focused)
                .environmentObject(HashtagViewModel(cabinet: OkamuraCabinet.shared))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .cornerRadius(6)
        .background(Color(nsColor: .controlBackgroundColor))
        .osxFocusRing(focused: focused)
    }
}
