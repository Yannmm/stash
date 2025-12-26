//
//  CollectionList.swift
//  Stash
//
//  Created by Yan Meng on 2025/12/16.
//

import SwiftUI


// A collection can be a group or hashtag
protocol Collection {
    
}


struct ManageViewSidebar: View {
    @Binding var selectedCollection: Collection?
    
    @State private var searchText = ""
    
    @Binding var groups: [Group]
    
    @Binding var hashtags: [Hashtag]
    
    private let tags = ClipTag.sampleData
    private let totalClips = 6
    
    var body: some View {
        VStack(spacing: 0) {
            // Traffic lights spacer
            HStack {
                Spacer()
                Button(action: {}) {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            // Search bar
            SearchBar(text: $searchText)
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    AllBookmarksRow(
                        count: totalClips,
                        selected: false,
                        onTap: {
//                            showAllClips = true
//                            selectedFolder = nil
//                            selectedTag = nil
                        }
                    )
                    GroupSection(groups: $groups)
                    TagSection(hashtags: $hashtags)
                }
                .padding(.horizontal, 16)
            }
            
            Spacer()
            
            // Footer
            FooterView()
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .background(Color(hex: 0x22242B))
    }
    
    
}

// MARK: - Search Bar

private struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.5))
            
            TextField("Search clips...", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.1))
        )
    }
}

// MARK: - All Clips Row

extension ManageViewSidebar {
    private struct AllBookmarksRow: View {
        let count: Int
        let selected: Bool
        let onTap: () -> Void
        
        @State private var isHovered = false
        
        var body: some View {
            Button(action: onTap) {
                HStack(spacing: 10) {
                    Image(systemName: "infinity")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                    
                    Text("All Bookmarks")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Text("\(count)")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selected ? Color.white.opacity(0.15) : (isHovered ? Color.white.opacity(0.08) : Color.clear))
                )
            }
            .buttonStyle(.plain)
            .onHover { isHovered = $0 }
        }
    }
}

extension ManageViewSidebar {
    private struct TagSection: View {
        @Binding var hashtags: [Hashtag]
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                // Tags Section
                SectionHeader(title: "TAGS")
                
                VStack(spacing: 0) {
                    ForEach(hashtags) { tag in
                        HashtagRow(
                            hashtag: tag,
                            isSelected: false,
                            action: {
//                                    selectedTag = tag
//                                    selectedFolder = nil
//                                    showAllClips = false
                            }
                        )
                    }
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
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text("#")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                
                Text(hashtag.name)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.9))
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.white.opacity(0.15) : (isHovered ? Color.white.opacity(0.08) : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Footer View

private struct FooterView: View {
    var body: some View {
        HStack {
            Text("Pro Account")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.5))
            
            Spacer()
            
            Text("70% used")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}


#Preview {
    let group1 = UUID()
    let group2 = UUID()
    let group3 = UUID()
    let child1 = UUID()
    let child2 = UUID()
    
    return ManageViewSidebar(
        selectedCollection: .constant(nil),
        groups: .constant([
            Group(id: group1, name: "Group 1", parentId: nil),
            Group(id: child1, name: "Child 1.1", parentId: group1),
            Group(id: child2, name: "Child 1.2", parentId: group1),
            Group(id: group2, name: "Group 2", parentId: nil),
            Group(id: group3, name: "Group 3", parentId: nil)
        ]),
        hashtags: .constant([
            Hashtag(name: "tag1"),
            Hashtag(name: "tag2"),
            Hashtag(name: "tag=3"),
        ])
    )
    .frame(width: 260, height: 700)
}
