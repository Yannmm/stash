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
        
        @State private var mode: Int = 0
        
        @State private var search = ""
        
        var body: some View {
            DraggableList()
                .searchable(text: $search, placement: .toolbar)
                .toolbar {
                    if #available(macOS 26.0, *) {
                        ToolbarItem(placement: .navigation) {
                            Text("Format")
                                .font(.system(size: 20, weight: .semibold))
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .sharedBackgroundVisibility(.hidden)
                    } else {
                        ToolbarItem(placement: .navigation) {
                            Text("Format")
                                .font(.title2)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                    }
                    // 2. Grouping primary actions together
                    ToolbarItemGroup(placement: .primaryAction) {
                        Picker("", selection: $mode) {
                            Image(systemName: "square.grid.2x2").tag(0)
                            Image(systemName: "list.bullet").tag(1)
                            Image(systemName: "rectangle.grid.1x2").tag(2)
                            Image(systemName: "rectangle").tag(3)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 180)

                        Button {
                            // viewModel.refresh()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }

                        Menu {
                            Button("New Folder") { }
                            Button("New Smart Folder") { }
                            Divider()
                            Button("Get Info") { }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                        
//                        ToolbarItem(placement: .automatic) {
//                                    
//                                }
                        Spacer()
                    }
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
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
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
                    .padding(.leading, Constant.leading1 + Constant.gap1 + Constant.iconWidth)
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
            HStack(spacing: 0) {
                ForEach(0..<row.trail.count, id: \.self) { _ in
                    Rectangle()
                        .frame(width: 1)
                        .frame(width: 12)
                        .frame(maxHeight: .infinity)
                        .foregroundColor(.random)
                }
                HStack(spacing: Constant.gap1) {
                    ViewHelper.icon(row.icon, side: Constant.iconWidth)
                    Text(row.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.leading, Constant.leading1)
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
    enum Constant {
        static let rowHeight: CGFloat = 36
        static let resizerWidth: CGFloat = 12
        static let initialWidth1: CGFloat = 280
        static let initialWidth2: CGFloat = 220
        static let initialWidth3: CGFloat = 100
        static let minWidth1: CGFloat = 180
        static let minWidth2: CGFloat = 120
        
        static let leading1: CGFloat = 24
        static let gap1: CGFloat = 12
        static let iconWidth: CGFloat = 16
    }
}
