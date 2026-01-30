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
        @StateObject var viewModel: GroupSectionViewModel
        
        var body: some View {
            List {
                RootRow(
                    count: 33,
                    selected: viewModel.selectionStore.collection == nil,
                    onTap: {
                        viewModel.selectionStore.collection = nil
                    }
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
