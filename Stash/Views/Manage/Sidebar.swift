//
//  CollectionList.swift
//  Stash
//
//  Created by Yan Meng on 2025/12/16.
//

import SwiftUI

extension ManageView {
    struct Sidebar: View {
        @Binding var collection: Collectible?
        @State private var searchText = ""
        @Binding var groups: [Group]
        @Binding var hashtags: [Hashtag]
        private let tags = ClipTag.sampleData
        private let totalClips = 6
        
        var body: some View {
            List {
                // All Bookmarks row
                AllBookmarksRow(
                    count: totalClips,
                    selected: collection == nil,
                    onTap: {
                        collection = nil
                    }
                )
                .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
                .listRowSeparator(.hidden)
                
                // Groups Section
                GroupSection(groups: $groups, selectedOne: Binding<Group?>(
                    get: {
                        collection as? Group
                    },
                    set: { newGroup in
                        collection = newGroup
                    }
                ))
                
                // Tags Section
                TagSection(hashtags: $hashtags)
            }
            .listStyle(.sidebar)
            .searchable(text: $searchText, prompt: "Search clips...")
            .safeAreaInset(edge: .bottom) {
                FooterView()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }
        }
        
        
    }
}




extension ManageView.Sidebar {
    private struct AllBookmarksRow: View {
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

extension ManageView.Sidebar {
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

// MARK: - Group Tree Node



// MARK: - Folder Row



// MARK: - Clip Tag Row

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

// MARK: - Footer View

private struct FooterView: View {
    var body: some View {
        HStack {
            Text("Pro Account")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text("70% used")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}


//#Preview {
//    let group1 = UUID()
//    let group2 = UUID()
//    let group3 = UUID()
//    let child1 = UUID()
//    let child2 = UUID()
//
//    return ManageViewSidebar(
//        selectedCollection: .constant(nil),
//        groups: .constant([
//            Group(id: group1, name: "Group 1", parentId: nil),
//            Group(id: child1, name: "Child 1.1", parentId: group1),
//            Group(id: child2, name: "Child 1.2", parentId: group1),
//            Group(id: group2, name: "Group 2", parentId: nil),
//            Group(id: group3, name: "Group 3", parentId: nil)
//        ]),
//        hashtags: .constant([
//            Hashtag(name: "tag1"),
//            Hashtag(name: "tag2"),
//            Hashtag(name: "tag=3"),
//        ])
//    )
//    .frame(width: 260, height: 700)
//}
