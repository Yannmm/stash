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
        @StateObject var viewModel: WorkbenchViewModel
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                Toolbar()
                    .padding(.horizontal, 12)
                
                Divider()
                
                DraggableList()
            }
            .background(Color(NSColor.textBackgroundColor))
            .toolbar {
                // Empty toolbar to prevent default sidebar toggle from appearing
            }
            .environmentObject(viewModel)
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
        
        // macOS 26 SwiftUI List reuse bug:
        // Row @State leaks after drag reorder.
        // Remove _version hack once fixed.
        @State private var _version = 0
        
        var body: some View {
            GeometryReader { proxy in
                ScrollView([.vertical, .horizontal]) {
                    VStack(spacing: 0) {
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
                                ForEach(Array(viewModel.rows.enumerated()), id: \.element.id) { index, row in
                                    Row(
                                        index: index,
                                        row: row,
                                        selection: $selection,
                                        dragging: $dragging,
                                        width1: width1,
                                        width2: width2,
                                        totalWidth: max(totalWidth, proxy.size.width),
                                        onDrop: { drag, over, insertAfter in
                                            withAnimation(.easeInOut(duration: 0.25)) {
                                                viewModel.moveRow(drag.id, to: over.id, insertAfter: insertAfter)
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                                    _version += 1
                                                }
                                            }
                                        }
                                    )
                                    .id("\(row.id)-\(_version)")
                                }
                            }
                        }
                        Spacer(minLength: 0)
                    }
//                    .frame(width: proxy.size.width)
                    .frame(minHeight: proxy.size.height)
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
        
        var body: some View {
            HStack(spacing: 0) {
                // Left: Navigation buttons
                HStack(spacing: 2) {
                    ToolbarButton(icon: "chevron.left", action: {})
                        .disabled(true)
                    ToolbarButton(icon: "chevron.right", action: {})
                        .disabled(true)
                }
                
                Spacer()
                
                // Center: Title and item count
                VStack(spacing: 2) {
                    Text(viewModel.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(countDescription)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Right: View toggle, actions, and search
                HStack(spacing: 8) {
                    ViewToggle()
                    
                    Divider()
                        .frame(height: 18)
                    
                    // Action buttons
                    HStack(spacing: 2) {
                        ToolbarButton(icon: "square.and.arrow.up", action: {})
                        ToolbarButton(icon: "tag", action: {})
                        
                        Menu {
                            Button("New Folder", action: {})
                            Button("Add Bookmark", action: {})
                            Divider()
                            Button("Sort By Name", action: {})
                            Button("Sort By Date", action: {})
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                                .frame(width: 28, height: 22)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Divider()
                        .frame(height: 18)
                    
                    SearchField(text: $viewModel.filter)
                }
            }
            .padding(.vertical, 6)
        }
        
        private var countDescription: String {
            if viewModel.groupCount > 0 {
                return "\(viewModel.bookmarkCount) items, \(viewModel.groupCount) folders"
            } else {
                return "\(viewModel.bookmarkCount) items"
            }
        }
    }
    
    private struct ToolbarButton: View {
        let icon: String
        let action: () -> Void
        
        @State private var isHovered = false
        @Environment(\.isEnabled) private var isEnabled
        
        var body: some View {
            Button(action: action) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isEnabled ? (isHovered ? .primary : .secondary) : .quaternary)
                    .frame(width: 28, height: 22)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(isHovered && isEnabled ? Color.gray.opacity(0.15) : Color.clear)
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { isHovered = $0 }
        }
    }
    
    private struct SearchField: View {
        @Binding var text: String
        @FocusState private var isFocused: Bool
        
        var body: some View {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                
                TextField("Search", text: $text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .focused($isFocused)
                
                if !text.isEmpty {
                    Button(action: { text = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(width: isFocused || !text.isEmpty ? 180 : 140)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isFocused ? Color.accentColor.opacity(0.5) : Color.gray.opacity(0.2), lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.15), value: isFocused)
            .animation(.easeInOut(duration: 0.15), value: text.isEmpty)
        }
    }
}

fileprivate extension ManageView.WorkbenchView {
    struct ViewToggle: View {
        @EnvironmentObject var viewModel: WorkbenchViewModel
        
        private let options: [(icon: String, hierarchy: WorkbenchViewModel.Hierarchy)] = [
            ("square.grid.2x2", .direct),
            ("list.bullet", .direct),
            ("rectangle.grid.1x2", .descendant),
            ("squares.below.rectangle", .descendant)
        ]
        
        var body: some View {
            HStack(spacing: 1) {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            viewModel.hierarchy = option.hierarchy
                        }
                    }) {
                        Image(systemName: option.icon)
                            .font(.system(size: 12))
                            .foregroundStyle(isSelected(index) ? .primary : .secondary)
                            .frame(width: 26, height: 20)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(isSelected(index) ? Color(NSColor.controlBackgroundColor) : Color.clear)
                                    .shadow(color: isSelected(index) ? Color.black.opacity(0.1) : Color.clear, radius: 1, y: 1)
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(2)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.12))
            )
        }
        
        private func isSelected(_ index: Int) -> Bool {
            // For now, index 1 (list) = .direct, index 2-3 = .descendant
            if viewModel.hierarchy == .direct {
                return index == 1
            } else {
                return index == 2
            }
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
