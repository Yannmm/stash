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
            List {
                RootRow(
                    row: SidebarViewModel.Row(id: UUID(), name: "All Bookmarks", level: 0, expanded: false, groupCount: 33, bookmarkCount: 44, selected: false)
                )
                GroupSection()
                TagSection(hashtags: .constant([]))
            }
            .listStyle(.sidebar)
            .environmentObject(viewModel)
        }
            
    }
}

fileprivate extension ManageView.Sidebar {
    struct RootRow: View {
        let row: SidebarViewModel.Row
        
        var body: some View {
            HStack(spacing: 6) {
                Image(systemName: "infinity")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .onTapGesture {
//                        onTap()
//                        guard row.groupCount > 0 else { return }
//                        onToggleExpansion()
                    }
                
                // Group name
                Text(row.name)
                    .font(.system(size: 14))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                // Count
                Text(row.groupCount > 0 ? "\(row.bookmarkCount)/\(row.groupCount)" : "\(row.bookmarkCount)")
                    .font(.system(size: 13))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.clear)
            )
            .contentShape(Rectangle())
            .onTapGesture {
//                onTap()
            }
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
