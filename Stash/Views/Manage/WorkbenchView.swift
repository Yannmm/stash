//
//  BookmarkList.swift
//  Stash
//
//  Created by Yan Meng on 2025/12/16.
//

import SwiftUI
import AppKit

extension ManageView {
    struct WorkbenchView: View {
        @EnvironmentObject var viewModel: WorkbenchViewModel
        
        private var title: String {
            if let c = viewModel.collection, let g = c as? Group {
                return g.name
            } else {
                return "All Bookmarks"
            }
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                Toolbar()
                .padding(.top, 12)
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
                
                List(bookmarks: viewModel.bookmarks)
            }
            .background(Color(NSColor.textBackgroundColor))
        }
    }
    struct List: View {
        let bookmarks: [Bookmark]
        @EnvironmentObject var cabinet: OkamuraCabinet
        
        var body: some View {
            Table(bookmarks) {
                TableColumn(Text("                   Name")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                ) { bookmark in
                    TableRowView(bookmark: bookmark, cabinet: cabinet)
                }
                .width(min: 200)
                
                TableColumn(Text("Group")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)) { bookmark in
                        GroupColumnView(bookmark: bookmark, cabinet: cabinet)
                    }
                    .width(min: 100)
            }
            .tableStyle(.bordered) // ⬅️ important
            .clipShape(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(Color.gray.opacity(0.25), lineWidth: 0.5)
            )
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
    
    // MARK: - Table Row View
    
    private struct TableRowView: View {
        let bookmark: Bookmark
        let cabinet: OkamuraCabinet
        
        var body: some View {
            HStack(spacing: 16) {
                ViewHelper.icon(bookmark.icon, side: 24)
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.gray.opacity(0.4), lineWidth: 0.5)
                    )
                
                // Title and domain
                VStack(alignment: .leading, spacing: 4) {
                    Text(bookmark.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "recordingtape")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary.opacity(0.6))
                        
                        Text(bookmark.url.host() ?? bookmark.url.absoluteString)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
            }
            .padding(.vertical, 6)
            .padding(.leading, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Group Column View
    
    private struct GroupColumnView: View {
        let bookmark: Bookmark
        let cabinet: OkamuraCabinet
        
        var group: Group? {
            cabinet.storedEntries.first(where: { $0.id == bookmark.parentId }) as? Group
        }
        
        var body: some View {
            Text(group?.name ?? "")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

extension ManageView.WorkbenchView {
    struct Toolbar: View {
        @EnvironmentObject var viewModel: WorkbenchViewModel
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(countDescription)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                HStack(alignment: .top) {
                    Text(viewModel.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.primary)
                    Spacer()
                    HStack(spacing: 12) {
                        SearchField(text: $viewModel.filter)
                        //                        ViewToggle(isListView: $isListView)
                        AddClipButton()
                    }
                }
            }
            .background(Color.clear)
        }
        
        var countDescription: AttributedString {
            func _make(_ count: Int, _ unit: String) -> AttributedString {
                var a1 = AttributedString("\(count) ")
                a1.foregroundColor = .secondary
                a1.font = .system(size: 14, weight: .bold)
                var a2 = AttributedString(unit)
                a2.foregroundColor = .gray
                a2.font = .system(size: 14, weight: .ultraLight)
                return a1 + a2
            }
            
            var v = AttributedString(" / ")
            v.foregroundColor = .gray
            v.font = .system(size: 14, weight: .ultraLight)
            
            return _make(viewModel.bookmarkCount, "Bookmarks") + v + _make(viewModel.groupCount, "Groups")
        }
    }
    
    private struct SearchField: View {
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
                .fixedSize()
            }
            .buttonStyle(.plain)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .onHover { isHovered = $0 }
            .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
    }
}

// MARK: - Color Extension

private extension Color {
    static let accentGreen = Color(red: 0.29, green: 0.73, blue: 0.45)
}

//#Preview {
//    ManageView.Content(
//        selectedFolder: nil,
//        selectedTag: nil,
//        showAllClips: true
//    )
//}
