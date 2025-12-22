//
//  BookmarkList.swift
//  Stash
//
//  Created by Yan Meng on 2025/12/16.
//

import SwiftUI

struct BookmarkList: View {
    let selectedFolder: Folder?
    let selectedTag: ClipTag?
    let showAllClips: Bool
    
    @State private var filterText = ""
    @State private var isListView = true
    
    private let clips = Clip.sampleData
    
    private var title: String {
        if showAllClips {
            return "All Clips"
        } else if let folder = selectedFolder {
            return folder.name
        } else if let tag = selectedTag {
            return "#\(tag.name)"
        }
        return "All Clips"
    }
    
    private var filteredClips: [Clip] {
        if filterText.isEmpty {
            return clips
        }
        return clips.filter { $0.title.localizedCaseInsensitiveContains(filterText) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HeaderView(
                title: title,
                itemCount: filteredClips.count,
                filterText: $filterText,
                isListView: $isListView
            )
            
            // Clip list
            ClipListView(clips: filteredClips)
        }
        .background(Color(NSColor.textBackgroundColor))
    }
}

// MARK: - Header View

private struct HeaderView: View {
    let title: String
    let itemCount: Int
    @Binding var filterText: String
    @Binding var isListView: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                // Title and count
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    Text("\(itemCount) items")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Controls
                HStack(spacing: 12) {
                    // Filter search
                    FilterField(text: $filterText)
                    
                    // View toggle
                    ViewToggle(isListView: $isListView)
                    
                    // Sort button
                    SortButton()
                    
                    // Add Clip button
                    AddClipButton()
                }
            }
        }
        .padding(.top, 40)
        .padding(.horizontal, 32)
        .padding(.bottom, 24)
    }
}

// MARK: - Filter Field

private struct FilterField: View {
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            
            TextField("Filter...", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(width: 160)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - View Toggle

private struct ViewToggle: View {
    @Binding var isListView: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: { isListView = true }) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 13))
                    .foregroundStyle(isListView ? .primary : .secondary)
                    .frame(width: 32, height: 28)
                    .background(isListView ? Color.gray.opacity(0.1) : Color.clear)
            }
            .buttonStyle(.plain)
            
            Button(action: { isListView = false }) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 13))
                    .foregroundStyle(!isListView ? .primary : .secondary)
                    .frame(width: 32, height: 28)
                    .background(!isListView ? Color.gray.opacity(0.1) : Color.clear)
            }
            .buttonStyle(.plain)
        }
        .background(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Sort Button

private struct SortButton: View {
    var body: some View {
        Menu {
            Button("Date Added") {}
            Button("Name") {}
            Button("Domain") {}
        } label: {
            HStack(spacing: 6) {
                Text("Sort")
                    .font(.system(size: 14))
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Clip Button

private struct AddClipButton: View {
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))
                Text("Add Clip")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.accentGreen)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}

// MARK: - Clip List View

private struct ClipListView: View {
    let clips: [Clip]
    
    var body: some View {
        VStack(spacing: 0) {
            // Table header
            HStack {
                Text("NAME")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("ADDED")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.03))
            
            Divider()
            
            // Clip rows
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(clips) { clip in
                        ClipRow(clip: clip)
                        Divider()
                            .padding(.leading, 32)
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
    }
}

// MARK: - Clip Row

private struct ClipRow: View {
    let clip: Clip
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Initial avatar
            Text(clip.initial)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            
            // Title, tags, and domain
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(clip.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)
                    
                    ForEach(clip.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "link")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary.opacity(0.7))
                    
                    Text(clip.domain)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Date
            Text(clip.formattedDate)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 14)
        .background(isHovered ? Color.gray.opacity(0.03) : Color.clear)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Color Extension

private extension Color {
    static let accentGreen = Color(red: 0.29, green: 0.73, blue: 0.45)
}
