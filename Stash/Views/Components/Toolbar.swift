//
//  Toolbar.swift
//  Stash
//
//  Created by Rayman on 2026/2/6.
//

import SwiftUI

extension ManageView.WorkbenchView {
    struct Toolbar: ToolbarContent {
        @Binding var hierarchy: WorkbenchViewModel.Hierarchy
        let title: String
        let groupCount: Int
        let bookmarkCount: Int

        var body: some ToolbarContent {
//            if #available(macOS 26.0, *) {
//                ToolbarItem(placement: .navigation) {
//                    Title(title: title, groupCount: groupCount, bookmarkCount: bookmarkCount)
//                }
//                .sharedBackgroundVisibility(hidden)
//            } else {
                ToolbarItem(placement: .navigation) {
                    Title(title: title, groupCount: groupCount, bookmarkCount: bookmarkCount)
                }
//            }
            
            ToolbarItemGroup(placement: .primaryAction) {
                Spacer()

                Picker("", selection: $hierarchy) {
                    Label("Children", systemImage: "list.bullet")
                        .tag(WorkbenchViewModel.Hierarchy.child)
                        .help("Show Direct Children")
                    Label("Descedants", systemImage: "list.bullet.indent")
                        .tag(WorkbenchViewModel.Hierarchy.descendant)
                        .help("Show All Descendants")
                }
                .pickerStyle(.segmented)
                .frame(width: 100)

                Button {
                    // refresh
                } label: {
                    Label("Add Bookmark", systemImage: "link.badge.plus")
                }
                .help("Add Bookmark")
                
                Button {
                    // refresh
                } label: {
                    Label("Add Group", systemImage: "folder.badge.plus")
                }
                .help("Add Group")
                

                Menu {
                    Button("New Folder") { }
                    Button("New Smart Folder") { }
                    Divider()
                    Button("Get Info") { }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
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
