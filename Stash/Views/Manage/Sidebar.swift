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
        @Binding var collection: Collectible?
        @Binding var groups: [Group]
        @Binding var hashtags: [Hashtag]
        
        var body: some View {
            List {
                RootRow(
                    count: 33,
                    selected: collection == nil,
                    onTap: {
                        collection = nil
                    }
                )
                GroupSection(groups: $groups, selectedOne: Binding<Group?>(
                    get: {
                        collection as? Group
                    },
                    set: { newGroup in
                        collection = newGroup
                    }
                ))
                TagSection(hashtags: $hashtags)
            }
            .listStyle(.sidebar)
        }
    }
}

fileprivate extension ManageView.Sidebar {
    struct RootRow: View {
        let count: Int
        let selected: Bool
        let onTap: () -> Void
        
        var body: some View {
            Button(action: onTap) {
                Label {
                    HStack {
                        Text("All Bookmarks")
                        Spacer()
                        Text("\(count)")
                            .foregroundStyle(.secondary)
                            .font(.callout)
                    }
                } icon: {
                    Image(systemName: "infinity")
                }
            }
            .buttonStyle(.plain)
            .listRowBackground(selected ? Color.accentColor.opacity(0.2) : Color.clear)
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
