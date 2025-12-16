//
//  CollectionList.swift
//  Stash
//
//  Created by Yan Meng on 2025/12/16.
//

import SwiftUI

// MARK: - Data Models

fileprivate struct BookmarkFolder: Identifiable {
    let id = UUID()
    let name: String
    var count: Int?
    var children: [BookmarkFolder] = []
}

fileprivate struct BookmarkTag: Identifiable {
    let id = UUID()
    let name: String
    var count: Int?
}

// MARK: - Main View

struct CollectionList: View {
    @State private var selectedBrowser = "Chrome bookmarks"
    @State private var expandedFolders: Set<UUID> = []
    
    let browsers = ["Chrome bookmarks", "Safari bookmarks", "Firefox bookmarks", "Edge bookmarks"]
    
    // Sample data
    fileprivate let folders: [BookmarkFolder] = [
        BookmarkFolder(name: "Design", count: 24),
        BookmarkFolder(name: "Code", count: 73, children: [
            BookmarkFolder(name: "Codepen", count: 12),
            BookmarkFolder(name: "JSFiddle"),
            BookmarkFolder(name: "CodeSandBox")
        ]),
        BookmarkFolder(name: "Inspiration", count: 37),
        BookmarkFolder(name: "Others", count: 42)
    ]
    
    fileprivate let tags: [BookmarkTag] = [
        BookmarkTag(name: "Dribbble", count: 2),
        BookmarkTag(name: "Code", count: 4),
        BookmarkTag(name: "Design", count: 1)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    Text("bookmark.io")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .padding(.top, 24)
                    
                    // Import Button
                    ImportButton()
                    
                    // Browser Picker
                    BrowserPicker(selection: $selectedBrowser, options: browsers)
                    
                    Divider()
                        .padding(.horizontal, 16)
                    
                    // All Bookmarks
                    AllBookmarksRow(count: 176)
                    
                    Divider()
                        .padding(.horizontal, 16)
                    
                    // Folders Section
                    FoldersSection(folders: folders, expandedFolders: $expandedFolders)
                    
                    // Tags Section
                    TagsSection(tags: tags)
                }
                .padding(.horizontal, 16)
            }
            
            Spacer()
            
            // Delete Collection Button
            DeleteCollectionButton()
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
        }
        .frame(minWidth: 260, maxWidth: 300)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Import Button

private struct ImportButton: View {
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 14, weight: .medium))
                Text("Import bookmarks")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentBlue)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}

// MARK: - Browser Picker

private struct BrowserPicker: View {
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(option) {
                    selection = option
                }
            }
        } label: {
            HStack {
                Text(selection)
                    .font(.system(size: 14))
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - All Bookmarks Row

private struct AllBookmarksRow: View {
    let count: Int
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "star")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
            
            Text("All bookmarks")
                .font(.system(size: 14))
                .foregroundStyle(.primary)
            
            Spacer()
            
            CountBadge(count: count)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color.gray.opacity(0.1) : Color.clear)
        )
        .onHover { isHovered = $0 }
    }
}

// MARK: - Folders Section

private struct FoldersSection: View {
    let folders: [BookmarkFolder]
    @Binding var expandedFolders: Set<UUID>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with Add button
            HStack {
                Text("Folders")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                AddButton(title: "Add folder", icon: "folder.badge.plus")
            }
            
            // Folder list
            VStack(spacing: 2) {
                ForEach(folders) { folder in
                    FolderRow(folder: folder, level: 0, expandedFolders: $expandedFolders)
                }
            }
        }
    }
}

// MARK: - Folder Row

private struct FolderRow: View {
    let folder: BookmarkFolder
    let level: Int
    @Binding var expandedFolders: Set<UUID>
    @State private var isHovered = false
    
    private var isExpanded: Bool {
        expandedFolders.contains(folder.id)
    }
    
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 8) {
                // Expand/Collapse indicator for folders with children
                if !folder.children.isEmpty {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 12)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if isExpanded {
                                    expandedFolders.remove(folder.id)
                                } else {
                                    expandedFolders.insert(folder.id)
                                }
                            }
                        }
                } else {
                    Spacer().frame(width: 12)
                }
                
                Image(systemName: "folder.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.accentBlue.opacity(0.7))
                
                Text(folder.name)
                    .font(.system(size: 14))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if let count = folder.count {
                    CountBadge(count: count)
                }
                
                MoreOptionsButton()
                    .opacity(isHovered ? 1 : 0)
            }
            .padding(.leading, CGFloat(level) * 20)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.gray.opacity(0.1) : Color.clear)
            )
            .onHover { isHovered = $0 }
            
            // Children
            if isExpanded {
                ForEach(folder.children) { child in
                    FolderRow(folder: child, level: level + 1, expandedFolders: $expandedFolders)
                }
            }
        }
    }
}

// MARK: - Tags Section

private struct TagsSection: View {
    let tags: [BookmarkTag]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with Add button
            HStack {
                Text("Tags")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                AddButton(title: "Add tag", icon: "tag")
            }
            
            // Tag list
            VStack(spacing: 2) {
                ForEach(tags) { tag in
                    TagRow(tag: tag)
                }
            }
        }
    }
}

// MARK: - Tag Row

private struct TagRow: View {
    let tag: BookmarkTag
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "tag")
                .font(.system(size: 14))
                .foregroundColor(.accentBlue.opacity(0.7))
            
            Text(tag.name)
                .font(.system(size: 14))
                .foregroundStyle(.primary)
            
            Spacer()
            
            if let count = tag.count {
                CountBadge(count: count)
            }
            
            MoreOptionsButton()
                .opacity(isHovered ? 1 : 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color.gray.opacity(0.1) : Color.clear)
        )
        .onHover { isHovered = $0 }
    }
}

// MARK: - Shared Components

private struct CountBadge: View {
    let count: Int
    
    var body: some View {
        Text("\(count)")
            .font(.system(size: 12))
            .foregroundColor(.accentBlue)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.accentBlue.opacity(0.3), lineWidth: 1)
            )
    }
}

private struct AddButton: View {
    let title: String
    let icon: String
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.accentBlue)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}

private struct MoreOptionsButton: View {
    var body: some View {
        Button(action: {}) {
            Text("•••")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
    }
}

private struct DeleteCollectionButton: View {
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 8) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                Text("Delete collection")
                    .font(.system(size: 14))
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .opacity(isHovered ? 0.7 : 1.0)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Color Extension

private extension Color {
    static let accentBlue = Color(red: 0.4, green: 0.5, blue: 0.9)
}

#Preview {
    CollectionList()
        .frame(width: 280, height: 700)
}
