//
//  Toolbar.swift
//  Stash
//
//  Created by Rayman on 2026/2/6.
//

import SwiftUI

extension ManageView.WorkbenchView {
    struct Toolbar: ToolbarContent {
        @Binding var mode: Int
        let title: String
        let groupCount: Int
        let bookmarkCount: Int

        var body: some ToolbarContent {
            if #available(macOS 26.0, *) {
                ToolbarItem(placement: .navigation) {
                    Title(title: title, groupCount: groupCount, bookmarkCount: bookmarkCount)
                }
                .sharedBackgroundVisibility(.hidden)
            } else {
                ToolbarItem(placement: .navigation) {
                    Title(title: title, groupCount: groupCount, bookmarkCount: bookmarkCount)
                }
            }
            
            ToolbarItemGroup(placement: .primaryAction) {
                Spacer()
                Picker("", selection: $mode) {
                    Image(systemName: "square.grid.2x2").tag(0)
                    Image(systemName: "list.bullet").tag(1)
                    Image(systemName: "rectangle.grid.1x2").tag(2)
                    Image(systemName: "rectangle").tag(3)
                }
                .pickerStyle(.segmented)
                .frame(width: 180)

                Button {
                    // viewModel.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }

                Menu {
                    Button("New Folder") { }
                    Button("New Smart Folder") { }
                    Divider()
                    Button("Get Info") { }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            

        }
        
        private struct Title: View {
            let title: String
            let groupCount: Int
            let bookmarkCount: Int
            
            var body: some View {
                HStack {
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.primary)
                    Text("\(bookmarkCount) Bookmarks | \(groupCount) Groups")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 6)
            }
        }
    }
}
