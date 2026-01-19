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
        
        @State private var selection: UUID?
        
        var body: some View {
            Table(viewModel.rows, selection: $selection) {
                tableColumns
            }
            .tableStyle(.bordered)
            // Combining clipShape and overlay for a clean border
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.gray.opacity(0.25), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        
        @TableColumnBuilder<WorkbenchViewModel.Row, Never> // Use TableColumnBuilder for clarity
        private var tableColumns: some TableColumnContent<WorkbenchViewModel.Row, Never> {
            TableColumn(
                Text("\tName")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            ) { row in
                IconAndNameCell(row: row)
            }
            .width(min: 150)
            TableColumn(
                Text("Description")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            ) { row in
                Text(row.description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .width(min: 60)
            TableColumn(
                Text("Tags")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            ) { row in
                Text(row.tags.joined(separator: ", "))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .width(min: 20)
        }
        
        private struct IconAndNameCell: View {
            let row: WorkbenchViewModel.Row
            
            var body: some View {
                HStack(spacing: 12) {
                    Text(String(repeating: "1", count: row.trail.count))
                    ViewHelper.icon(row.icon, side: 16)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(row.title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                .padding(.vertical, 6)
//                .padding(.leading, 12 + 16 * CGFloat(row.trail.count))
                .padding(.leading, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        
        // MARK: - Group Column View
        
        private struct TextCell: View {
            let text: String
            
            var body: some View {
                Text(text)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

fileprivate extension ManageView.WorkbenchView {
    struct Toolbar: View {
        @EnvironmentObject var viewModel: WorkbenchViewModel
        
        @State private var favoriteColor = 0
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text(viewModel.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.primary)
                    Spacer()
                    HStack(spacing: 12) {
                        SearchField(text: $viewModel.filter)
                        AddBookmarkButton()
                    }
                }
                HStack {
                    Text(countDescription)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                    Spacer()
                    ViewToggle()
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

fileprivate extension ManageView.WorkbenchView {
    struct ViewToggle: View {
        @EnvironmentObject var viewModel: WorkbenchViewModel
        
        var body: some View {
            HStack(spacing: 0) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.hierarchy = .direct
                    }
                }) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 13))
                        .foregroundStyle(viewModel.hierarchy == .direct ? .primary : .secondary)
                        .frame(width: 32, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.hierarchy = .descendant
                    }
                }) {
                    Image(systemName: "list.bullet.indent")
                        .font(.system(size: 13))
                        .foregroundStyle(viewModel.hierarchy == .descendant ? .primary : .secondary)
                        .frame(width: 32, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 32, height: 28)
                        .offset(x: viewModel.hierarchy == .direct ? -16 : 16)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                }
            )
        }
    }
}
