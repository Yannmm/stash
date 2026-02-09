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
            ScrollView {
                LazyVStack(spacing: 0) {
                    GroupSection.Row(
                        row: viewModel.rootRow,
                        icon: "infinity",
                        dragging: .constant(nil),
                        onToggleExpansion: {},
                        onTap: {
                            viewModel.setSelection(nil)
                        },
                        onDrop: { _, __, ___ in
                            
                        },
                    cascade: { _, __ in
                        return false
                    })
                    GroupSection()
                    TagSection(hashtags: .constant([]))
                }
                .padding(.horizontal, 16)
            }
            .environmentObject(viewModel)
        }
    }
}

fileprivate extension ManageView.Sidebar {
    private struct TagSection: View {
        @Binding var hashtags: [Hashtag]
        
        var body: some View {
            Section {
                ForEach(hashtags) { tag in
                    HashtagRow(
                        hashtag: tag,
                        isSelected: false,
                        action: {
                            // TODO: Handle tag selection
                        }
                    )
                }
            } header: {
                SectionHeader(title: "Tags")
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
