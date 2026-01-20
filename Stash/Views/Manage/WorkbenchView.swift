//
//  BookmarkList.swift
//  Stash
//
//  Created by Yan Meng on 2025/12/16.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

extension ManageView {
    struct WorkbenchView: View {
        @EnvironmentObject var viewModel: WorkbenchViewModel
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                Toolbar()
                    .padding(.top, 12)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)
                
                DraggableList()
            }
            .background(Color(NSColor.textBackgroundColor))
        }
    }
}

// MARK: - Drop Position Alias

fileprivate extension ManageView.WorkbenchView {
    typealias DropPosition = WorkbenchViewModel.DropPosition
}

// MARK: - Draggable List

fileprivate extension ManageView.WorkbenchView {
    private struct DraggableList: View {
        @EnvironmentObject var viewModel: WorkbenchViewModel
        
        @State private var selection: UUID?
        @State private var draggingRow: WorkbenchViewModel.Row?
        
        var body: some View {
            VStack(spacing: 0) {
                // Table Header
                TableHeader()
                
                // Scrollable rows
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.rows) { row in
                            TableRow(
                                row: row,
                                isSelected: selection == row.id,
                                draggingRow: $draggingRow,
                                onSelect: { selection = row.id },
                                onDrop: { droppedRow, targetRow, position in
                                    viewModel.moveRow(from: droppedRow.id, to: targetRow.id, position: position)
                                }
                            )
                        }
                    }
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.gray.opacity(0.25), lineWidth: 0.5)
            )
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Table Header

fileprivate extension ManageView.WorkbenchView {
    private struct TableHeader: View {
        var body: some View {
            HStack(spacing: 0) {
                Text("Name")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 12)
                
                Text("Description")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 200, alignment: .leading)
                
                Text("Tags")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 150, alignment: .leading)
            }
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))
            .overlay(
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 1),
                alignment: .bottom
            )
        }
    }
}

// MARK: - Table Row with Drag and Drop

fileprivate extension ManageView.WorkbenchView {
    private struct TableRow: View {
        let row: WorkbenchViewModel.Row
        let isSelected: Bool
        @Binding var draggingRow: WorkbenchViewModel.Row?
        let onSelect: () -> Void
        let onDrop: (WorkbenchViewModel.Row, WorkbenchViewModel.Row, DropPosition) -> Void
        
        @State private var isHovered = false
        @State private var dragOver = false
        @State private var dragOverPosition: DropPosition? = nil
        
        private let rowHeight: CGFloat = 36
        
        var body: some View {
            VStack(spacing: 0) {
                // Drop indicator line (before)
                if dragOver && dragOverPosition == .before {
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(height: 2)
                }
                
                // Row content
                HStack(spacing: 0) {
                    // Name column
                    IconAndNameCell(row: row)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Description column
                    Text(row.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(width: 200, alignment: .leading)
                    
                    // Tags column
                    Text(row.tags.joined(separator: ", "))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(width: 150, alignment: .leading)
                }
                .frame(height: rowHeight)
                .background(backgroundColor)
                .contentShape(Rectangle())
                .onTapGesture { onSelect() }
                .onHover { isHovered = $0 }
                .onDrag {
                    draggingRow = row
                    return NSItemProvider(object: row.id.uuidString as NSString)
                } preview: {
                    // Drag preview
                    HStack(spacing: 8) {
                        ViewHelper.icon(row.icon, side: 16)
                        Text(row.title)
                            .font(.system(size: 14))
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.95))
                    .cornerRadius(6)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .onDrop(of: [UTType.plainText], delegate: RowDropDelegate(
                    row: row,
                    draggedRow: $draggingRow,
                    dragOver: $dragOver,
                    dragOverPosition: $dragOverPosition,
                    rowHeight: rowHeight,
                    onDrop: onDrop
                ))
                
                // Drop indicator line (after)
                if dragOver && dragOverPosition == .after {
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(height: 2)
                }
                
                // Separator line
                if !dragOver || dragOverPosition != .after {
                    Rectangle()
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 1)
                }
            }
        }
        
        private var backgroundColor: Color {
            if isSelected {
                return Color.accentColor.opacity(0.15)
            } else if isHovered {
                return Color.gray.opacity(0.08)
            }
            return Color.clear
        }
    }
}

// MARK: - Row Drop Delegate

fileprivate extension ManageView.WorkbenchView {
    private struct RowDropDelegate: DropDelegate {
        let row: WorkbenchViewModel.Row
        @Binding var draggedRow: WorkbenchViewModel.Row?
        @Binding var dragOver: Bool
        @Binding var dragOverPosition: DropPosition?
        let rowHeight: CGFloat
        let onDrop: (WorkbenchViewModel.Row, WorkbenchViewModel.Row, DropPosition) -> Void
        
        // Only before/after zones - middle zone is rejected
        private var threshold: CGFloat { rowHeight / 2 }
        
        func validateDrop(info: DropInfo) -> Bool {
            guard let draggedRow = draggedRow else { return false }
            return draggedRow.id != row.id
        }
        
        func performDrop(info: DropInfo) -> Bool {
            guard let draggedRow = draggedRow,
                  draggedRow.id != row.id,
                  let position = dragOverPosition else {
                resetState()
                return false
            }
            
            onDrop(draggedRow, row, position)
            self.draggedRow = nil
            resetState()
            return true
        }
        
        func dropEntered(info: DropInfo) {
            guard draggedRow?.id != row.id else { return }
            dragOver = true
        }
        
        func dropExited(info: DropInfo) {
            resetState()
        }
        
        func dropUpdated(info: DropInfo) -> DropProposal? {
            guard draggedRow?.id != row.id else {
                return DropProposal(operation: .forbidden)
            }
            
            let location = info.location
            
            // Only allow dropping in top or bottom zone, reject middle
            if location.y < threshold {
                dragOverPosition = .before
                return DropProposal(operation: .move)
            } else {
                dragOverPosition = .after
                return DropProposal(operation: .move)
            }
        }
        
        private func resetState() {
            dragOver = false
            dragOverPosition = nil
        }
    }
}

// MARK: - Icon and Name Cell

fileprivate extension ManageView.WorkbenchView {
    private struct IconAndNameCell: View {
        let row: WorkbenchViewModel.Row
        
        var body: some View {
            HStack(spacing: 12) {
                ForEach(0..<row.trail.count, id: \.self) { _ in
                    Rectangle()
                        .frame(width: 1)
                        .frame(width: 12)
                        .frame(maxHeight: .infinity)
                        .foregroundColor(.random)
                }
                HStack(spacing: 12) {
                    ViewHelper.icon(row.icon, side: 16)
                    Text(row.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.leading, 12)
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
