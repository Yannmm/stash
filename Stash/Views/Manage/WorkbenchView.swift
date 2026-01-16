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
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                Toolbar()
                    .padding(.top, 12)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)
                
                List()
            }
            .background(Color(NSColor.textBackgroundColor))
        }
    }
}

fileprivate extension ManageView.WorkbenchView {
    private struct List: View {
        @EnvironmentObject var viewModel: WorkbenchViewModel
        
        var body: some View {
            table
        }
        
        // TODO: most of code of table1 and table2 are duplicate.
        private var table: some View {
            Table(viewModel.rows) {
                TableColumn(Text("                   Name")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                ) { row in
                    TableRowView(row: row)
                }
                .width(min: 200)
                TableColumn(Text("Group & Tags")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)) { row in
                        GroupColumnView(row: row)
                    }
                    .width(min: 60)
                
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
        
        
        // MARK: - Table Row View
        
        private struct TableRowView: View {
            let row: WorkbenchViewModel.Row
            
            var body: some View {
                HStack(spacing: 16) {
                    ViewHelper.icon(row.icon, side: 24)
                        .foregroundStyle(.secondary)
                        .frame(width: 36, height: 36)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 0.5)
                        )
                    
                    // Title and domain
                    VStack(alignment: .leading, spacing: 4) {
                        Text(row.title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        
                        HStack(spacing: 4) {
//                            Image(systemName: "recordingtape")
//                                .font(.system(size: 9))
//                                .foregroundStyle(.secondary.opacity(0.6))
                            
                            Text(row.description)
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
            let row: WorkbenchViewModel.Row
            
            var body: some View {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trailDescription)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text("#tag1, #tag2")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                }
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            var trailDescription: AttributedString {
                let trail = row.trail
                if trail.isEmpty {
                    var a = AttributedString("/")
                    a.font = .system(size: 14, weight: .regular)
                    a.foregroundColor = .secondary
                    return a
                } else {
                    var separator = AttributedString("/")
                    separator.font = .system(size: 14, weight: .light)
                    separator.foregroundColor = .secondary
                    
                    let combined: AttributedString = trail.reduce(into: AttributedString()) { result, string in
                        if !result.characters.isEmpty {
                            result.append(separator)
                        }
                        var a = AttributedString(string)
                        a.font = .system(size: 14, weight: .regular)
                        a.foregroundColor = .secondary
                        result.append(a)
                    }
                    return combined
                }
            }
        }
    }
}

fileprivate extension ManageView.WorkbenchView {
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
                        AddBookmarkButton()
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
            
            if (viewModel.groupCount > 0) {
                var v = AttributedString(" / ")
                v.foregroundColor = .gray
                v.font = .system(size: 14, weight: .ultraLight)
                return _make(viewModel.bookmarkCount, "Bookmarks") + v + _make(viewModel.groupCount, "Groups")
            } else {
                return _make(viewModel.bookmarkCount, "Bookmarks")
            }
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
    
    private struct AddBookmarkButton: View {
        @State private var isHovered = false
        
        var body: some View {
            Button(action: {}) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Add Bookmark")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.green)
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
