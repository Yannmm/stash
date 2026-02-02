//
//  CollectionList.swift
//  Stash
//
//  Created by Yan Meng on 2025/12/16.
//

import SwiftUI
import AppKit

extension ManageView {
    struct Sidebar: View {
        @StateObject var viewModel: SidebarViewModel
        
        var body: some View {
            //            List {
            //                GroupSection.Row(
            //                    row: viewModel.rootRow,
            //                    dragging: .constant(nil),
            //                    onToggleExpansion: {},
            //                    onTap: {
            //                        viewModel.setSelection(nil)
            //                    },
            //                    onDrop: { _, __, ___ in
            //
            //                    })
            //                GroupSection()
            //                TagSection(hashtags: .constant([]))
            //            }
            //            .listStyle(.sidebar)
            //            .environmentObject(viewModel)
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    GroupSection.Row(
                        row: viewModel.rootRow,
                        dragging: .constant(nil),
                        onToggleExpansion: {},
                        onTap: {
                            viewModel.setSelection(nil)
                        },
                        onDrop: { _, __, ___ in
                            
                        })
                    GroupSection()
                    TagSection(hashtags: .constant([]))
                }
            }
            .environmentObject(viewModel)
        }
    }
}

fileprivate extension ManageView.Sidebar {
    private struct TagSection: View {
        @Binding var hashtags: [Hashtag]
        
        var body: some View {
            Section("Tags") {
                ForEach(hashtags) { tag in
                    HashtagRow(
                        hashtag: tag,
                        isSelected: false,
                        action: {
                            // TODO: Handle tag selection
                        }
                    )
                }
            }
        }
    }
}

private struct HashtagRow: View {
    let hashtag: Hashtag
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label(hashtag.name, systemImage: "number")
        }
        .buttonStyle(.plain)
        .listRowBackground(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
    }
}
