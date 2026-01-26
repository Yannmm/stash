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

// MARK: - Draggable List

fileprivate extension ManageView.WorkbenchView {
    private struct DraggableList: View {
        @EnvironmentObject var viewModel: WorkbenchViewModel
        
        @State private var selection: UUID?
        @State private var dragging: WorkbenchViewModel.Row?
        @State private var width1: CGFloat = Constant.initialWidth1
        @State private var width2: CGFloat = Constant.initialWidth2
        @State private var width3: CGFloat = Constant.initialWidth3
        
        var body: some View {
            GeometryReader { proxy in
                ScrollView([.vertical, .horizontal]) {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        Section(
                            header: Header(
                                width1: $width1,
                                width2: $width2,
                                min1: Constant.minWidth1,
                                min2: Constant.minWidth2,
                                total: max(totalWidth, proxy.size.width)
                            )
                        )
                        {
                            ForEach(viewModel.rows.indices, id: \.self) { index in
                                Row(
                                    index: index,
                                    row: viewModel.rows[index],
                                    selection: $selection,
                                    dragging: $dragging,
                                    width1: width1,
                                    width2: width2,
                                    totalWidth: max(totalWidth, proxy.size.width),
                                    onDrop: { drag, over, insertAfter in
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            viewModel.moveRow(drag.id, to: over.id, insertAfter: insertAfter)
                                        }
                                    }
                                )
                            }
                        }
                    }
                }
                .onChange(of: proxy.size.width) { _, newWidth in
                    let delta = newWidth - totalWidth
                    if delta != 0 {
                        let proposed = width1 + delta
                        width1 = max(Constant.minWidth1, proposed)
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
        
        private var totalWidth: CGFloat {
            width1 + width2 + width3 + Constant.resizerWidth * 2
        }
    }
}

// MARK: - Table Header

fileprivate extension ManageView.WorkbenchView {
    private struct Header: View {
        @Binding var width1: CGFloat
        @Binding var width2: CGFloat
        let min1: CGFloat
        let min2: CGFloat
        let total: CGFloat
        
        var body: some View {
            HStack(spacing: 0) {
                Text("Name")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 12 * 4)
                    .frame(width: width1, alignment: .leading)
                
                ColumnWidthDragger(width: $width1, min: min1)
                
                Text("Description")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: width2, alignment: .leading)
                
                ColumnWidthDragger(width: $width2, min: min2)
                
                Text("Tags")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: total, height: 28)
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
    struct Row: View {
        let index: Int
        let row: WorkbenchViewModel.Row
        @Binding var selection: UUID?
        @Binding var dragging: WorkbenchViewModel.Row?
        let width1: CGFloat
        let width2: CGFloat
        let totalWidth: CGFloat
        let onDrop: (WorkbenchViewModel.Row, WorkbenchViewModel.Row, Bool) -> Void
        @State private var dragPosition: DragPosition? = nil
        private var height: CGFloat { Constant.rowHeight }
        
        var body: some View {
            VStack(spacing: 0) {
                // Row content
                HStack(spacing: 0) {
                    // Name column
                    IconAndNameCell(row: row)
                        .frame(width: width1, alignment: .leading)
                    
                    Spacer()
                        .frame(width: Constant.resizerWidth)
                    
                    // Description column
                    Text(row.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(width: width2, alignment: .leading)
                    
                    Spacer()
                        .frame(width: Constant.resizerWidth)
                    
                    // Tags column
                    Text(row.tags.joined(separator: ", "))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: height)
                .background(backgroundColor)
                .overlay(alignment: .top) {
                    if dragPosition == .before {
                        Rectangle()
                            .fill(Color.accentColor)
                            .frame(height: 2)
                    }
                }
                .overlay(alignment: .bottom) {
                    if dragPosition == .after {
                        Rectangle()
                            .fill(Color.accentColor)
                            .frame(height: 2)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { selection = row.id }
                .onDrag {
                    selection = row.id
                    dragging = row
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
                .onDrop(of: [UTType.plainText], delegate: Dropper(
                    current: row,
                    dragging: $dragging,
                    dragPosition: $dragPosition,
                    rowHeight: height,
                    onDrop: onDrop
                ))
            }
            .frame(width: totalWidth, alignment: .leading)
        }
        
        private var backgroundColor: Color {
            if selection == row.id {
                return Color.accentColor.opacity(0.15)
            }
            let colors = NSColor.alternatingContentBackgroundColors
            return Color(colors[index % colors.count])
        }
    }
}



// MARK: - Row Drop Delegate

fileprivate extension ManageView.WorkbenchView.Row {
    enum DragPosition {
        case over
        case before
        case after
    }
    
    struct Dropper: SwiftUI.DropDelegate {
        let current: WorkbenchViewModel.Row
        @Binding var dragging: WorkbenchViewModel.Row?
        @Binding var dragPosition: DragPosition?
        let rowHeight: CGFloat
        let onDrop: (WorkbenchViewModel.Row, WorkbenchViewModel.Row, Bool) -> Void
        
        // Only before/after zones - middle zone is rejected
        private var threshold: CGFloat { rowHeight / 3 }
        
        func validateDrop(info: DropInfo) -> Bool {
            guard let drag = dragging else { return false }
            return drag.id != current.id
        }
        
        func performDrop(info: DropInfo) -> Bool {
            guard let drag = dragging,
                  drag.id != current.id,
                  let position = dragPosition, position == .before || position == .after else {
                reset()
                return false
            }
            
            onDrop(drag, current, position == .after)
            self.dragging = nil
            reset()
            return true
        }
        
        func dropEntered(info: DropInfo) {
            guard dragging?.id != current.id else { return }
            dragPosition = .over
        }
        
        func dropExited(info: DropInfo) {
            reset()
        }
        
        func dropUpdated(info: DropInfo) -> DropProposal? {
            guard dragging?.id != current.id else {
                return DropProposal(operation: .forbidden)
            }
            
            let location = info.location
            
            // Only allow dropping near top or bottom, reject middle
            if location.y < threshold {
                dragPosition = .before
                return DropProposal(operation: .move)
            } else if location.y > (rowHeight - threshold) {
                dragPosition = .after
                return DropProposal(operation: .move)
            } else {
                dragPosition = nil
                return DropProposal(operation: .forbidden)
            }
        }
        
        private func reset() {
            dragPosition = nil
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
        static let rowHeight: CGFloat = 36
        static let resizerWidth: CGFloat = 12
        static let initialWidth1: CGFloat = 280
        static let initialWidth2: CGFloat = 220
        static let initialWidth3: CGFloat = 100
        static let minWidth1: CGFloat = 180
        static let minWidth2: CGFloat = 120
    }
}
