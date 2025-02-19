//
//  BookmarkListView.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/9.
//

import SwiftUI

struct BookmarkListView: View {
    @EnvironmentObject var manager: OkamuraCabinet
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Button("Show Drop Window") {
                NSApp.activate(ignoringOtherApps: true)
                AppDelegate.shared.showDropWindow()
            }
            .buttonStyle(.plain) // Use the shorthand for PlainButtonStyle
            .frame(minWidth: 100, maxWidth: .infinity, minHeight: 44)
            .background(Color.green)
            .contentShape(Rectangle()) // <-- This makes the entire area tappable
            
//         Rectangle()
//            .fill(Color.red)
//            .frame(height: 5)
//            .edgesIgnoringSafeArea(.horizontal)
//            
//            List(manager.entries, id: \.self) { bookmark in
//                HStack {
//                    VStack(alignment: .leading) {
//                        Text(bookmark.title)
//                        Text(bookmark.url.absoluteString)
//                            .foregroundColor(.secondary)
//                            .font(.caption)
//                    }
//                    
//                    Button(action: { copyToClipboard(bookmark.url) }) {
//                        Image(systemName: "doc.on.doc")
//                    }
//                    Button(action: { openURL(bookmark.url) }) {
//                        Image(systemName: "arrowshape.turn.up.right")
//                    }
//                }
//            }
//            .listStyle(SidebarListStyle())
        }
        .frame(width: 300, height: 400)
    }
    
    private func copyToClipboard(_ url: URL) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url.absoluteString, forType: .URL)
    }
    
    private func openURL(_ url: URL) {
        NSWorkspace.shared.open(url)
    }
}

#Preview {
    BookmarkListView()
}
