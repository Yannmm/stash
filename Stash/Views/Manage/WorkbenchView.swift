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
        @State private var columnWidth1: CGFloat = 280
        @State private var columnWidth2: CGFloat = 220
        @State private var columnWidth3: CGFloat = 180
        
        var body: some View {
            GeometryReader { proxy in
                //                VStack(alignment: .leading, spacing: 0) {
                //                    TableHeader(
                //                        columnWidth1: $columnWidth1,
                //                        columnWidth2: $columnWidth2,
                //                        columnWidth3: $columnWidth3,
                //                        totalWidth: max(totalWidth, proxy.size.width)
                //                    )
                
                
                
                // Scrollable content
                ScrollView([.vertical, .horizontal]) {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        Section(
                            header: TableHeader(
                                columnWidth1: $columnWidth1,
                                columnWidth2: $columnWidth2,
                                columnWidth3: $columnWidth3,
                                totalWidth: max(totalWidth, proxy.size.width)
                            )
                            //                                )
                        )
                        {
                            ForEach(viewModel.rows) { row in
                                TableRow(
                                    row: row,
                                    isSelected: selection == row.id,
                                    draggingRow: $draggingRow,
                                    column1Width: columnWidth1,
                                    column2Width: columnWidth2,
                                    column3Width: columnWidth3,
                                    totalWidth: max(totalWidth, proxy.size.width),
                                    onSelect: { selection = row.id },
                                    onDrop: { droppedRow, targetRow, position in
                                        viewModel.moveRow(from: droppedRow.id, to: targetRow.id, position: position)
                                    }
                                )
                            }
                        }
                    }
                    //                        .frame(minWidth: max(totalWidth, proxy.size.width), alignment: .leading)
                }
                //                }
                
                .onChange(of: proxy.size.width) { newWidth in
                    
                    let delta = newWidth - totalWidth
                    print("xxx -> \(delta)")
                    if delta != 0 {
                        let proposed = columnWidth1 + delta
                        columnWidth1 = max(Constant.column1MinWidth, proposed)
                    }
                    //                    recentTotalWidth = newWidth
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
        
        private var totalWidth: CGFloat {
            columnWidth1 + columnWidth2 + columnWidth3 + Constant.resizerWidth * 2
        }
    }
}

// MARK: - Table Header

fileprivate extension ManageView.WorkbenchView {
    private struct TableHeader: View {
        @Binding var columnWidth1: CGFloat
        @Binding var columnWidth2: CGFloat
        @Binding var columnWidth3: CGFloat
        let totalWidth: CGFloat
        
        var body: some View {
            HStack(spacing: 0) {
                Text("Name")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 12 * 4)
                    .frame(width: columnWidth1, alignment: .leading)
                
                ColumnWidthDragger(width: $columnWidth1, min: 180)
                
                Text("Description")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: columnWidth2, alignment: .leading)
                
                ColumnWidthDragger(width: $columnWidth2, min: 140)
                
                Text("Tags")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                //                    .frame(width: columnWidth3, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: totalWidth, height: 28)
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
        let column1Width: CGFloat
        let column2Width: CGFloat
        let column3Width: CGFloat
        let totalWidth: CGFloat
        let onSelect: () -> Void
        let onDrop: (WorkbenchViewModel.Row, WorkbenchViewModel.Row, DropPosition) -> Void
        
        //        @State private var isHovered = false
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
                        .frame(width: column1Width, alignment: .leading)
                    
                    Spacer()
                        .frame(width: Constant.resizerWidth)
                    
                    // Description column
                    Text(row.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(width: column2Width, alignment: .leading)
                    
                    Spacer()
                        .frame(width: Constant.resizerWidth)
                    
                    // Tags column
                    Text(row.tags.joined(separator: ", "))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    //                        .frame(width: tagsWidth, alignment: .leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: rowHeight)
                .background(backgroundColor)
                .contentShape(Rectangle())
                .onTapGesture { onSelect() }
                //                .onHover { isHovered = $0 }
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
            .frame(width: totalWidth, alignment: .leading)
        }
        
        private var backgroundColor: Color {
            if isSelected {
                return Color.accentColor.opacity(0.15)
            }
            //            else if isHovered {
            //                return Color.gray.opacity(0.08)
            //            }
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
        private var threshold: CGFloat { rowHeight / 3 }
        
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
            
            // Only allow dropping near top or bottom, reject middle
            if location.y < threshold {
                dragOverPosition = .before
                return DropProposal(operation: .move)
            } else if location.y > (rowHeight - threshold) {
                dragOverPosition = .after
                return DropProposal(operation: .move)
            } else {
                dragOverPosition = nil
                return DropProposal(operation: .forbidden)
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

// MARK: - Column Resizer

fileprivate extension ManageView.WorkbenchView {
    private struct ColumnWidthDragger: View {
        @Binding var width: CGFloat
        let min: CGFloat
        
        @State private var startWidth: CGFloat?
        @State private var startX: CGFloat?
        @State private var hovering = false
        
        var body: some View {
            Rectangle()
                .fill(Color.gray.opacity(0.35))
                .frame(width: 1)
                .frame(width: Constant.resizerWidth)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
                .onHover { hovering in
                    self.hovering = hovering
                    if hovering {
                        NSCursor.resizeLeftRight.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                }
                .highPriorityGesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .global)
                        .onChanged { value in
                            if startWidth == nil {
                                startWidth = width
                                startX = value.startLocation.x
                            }
                            let delta = value.location.x - (startX ?? value.startLocation.x)
                            let proposed = (startWidth ?? width) + delta
                            width = max(min, proposed)
                        }
                        .onEnded { _ in
                            startWidth = nil
                            startX = nil
                        }
                )
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

fileprivate extension ManageView.WorkbenchView {
    enum Constant {
        static let resizerWidth: CGFloat = 12
        static let column1MinWidth: CGFloat = 180
    }
}
