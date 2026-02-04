//
//  GroupSection.swift
//  Stash
//
//  Created by Rayman on 2025/12/25.
//

import SwiftUI
import UniformTypeIdentifiers

extension ManageView.Sidebar {
    struct GroupSection: View {
        @EnvironmentObject var viewModel: SidebarViewModel
        @State private var dragging: SidebarViewModel.Row?
        
        // macOS 26 SwiftUI List reuse bug:
        // Row @State leaks after drag reorder.
        // Remove _version hack once fixed.
        @State private var _version = 0
        
        var body: some View {
            if viewModel.rows.count > 0 {
                Section {
                    ForEach(viewModel.rows, id: \.id) { row in
                        Row(
                            row: row,
                            icon: nil,
                            dragging: $dragging,
                            onToggleExpansion: {
                                viewModel.toggleExpansion(row.id)
                            },
                            onTap: {
                                viewModel.setSelection(row.id)
                            },
                            onDrop: { hostId, guestId, insertAfter in
                                print("drag popsition: \(insertAfter)")
                                _version += 1
                            },
                            adjacent: { hostId, guestId in
                                viewModel.adjacent(hostId, guestId: guestId)
                            }
                        )
                        .id("\(row.id)-\(_version)")
                    }
                } header: {
                    SectionHeader(title: "Groups")
                }
            }
        }
        
        private func handleDrop(droppedGroup: Group, targetGroup: Group?) {
            //            guard let droppedIndex = viewModel.groups.firstIndex(where: { $0.id == droppedGroup.id }) else { return }
            //
            //            var updatedGroup = droppedGroup
            //
            //            switch position {
            //            case .on:
            //                // Drop on target group (make it a child)
            //                updatedGroup.parentId = targetGroup?.id
            //            case .before, .after:
            //                // Drop before/after target group (same level as target)
            //                updatedGroup.parentId = targetGroup?.parentId
            //            }
            //
            //            // Prevent dropping on itself
            //            if updatedGroup.parentId == updatedGroup.id {
            //                return
            //            }
            //
            //            // Prevent circular references: check if the new parent is a descendant of the dragged group
            //            if let newParentId = updatedGroup.parentId,
            //               isDescendant(of: newParentId, ancestor: updatedGroup.id, in: viewModel.groups) {
            //                return
            //            }
            //
            //            // Create a new array to ensure SwiftUI detects the change
            //            var newGroups = viewModel.groups
            //
            //            // Remove the group from its current position
            //            newGroups.remove(at: droppedIndex)
            //
            //            // Find the new insertion point
            //            if let targetGroup = targetGroup, let targetIndex = newGroups.firstIndex(where: { $0.id == targetGroup.id }) {
            //                let insertIndex: Int
            //                if position == .on {
            //                    // Insert at the end of the target's children
            //                    insertIndex = targetIndex + 1
            //                } else {
            //                    // Adjust target index based on position
            //                    insertIndex = position == .after ? targetIndex + 1 : targetIndex
            //                }
            //                let safeIndex = min(max(0, insertIndex), newGroups.count)
            //                newGroups.insert(updatedGroup, at: safeIndex)
            //            } else {
            //                // Dropping at root level, just append
            //                newGroups.append(updatedGroup)
            //            }
            //
            //            // Assign the new array to trigger view update
            //            withAnimation(.easeInOut(duration: 0.2)) {
            //                // TODO edit
            ////                viewModel.groups = newGroups
            //            }
        }
    }
    
    //    enum DragPosition {
    //        case on
    //        case before
    //        case after
    //    }
}

//extension ManageView.Sidebar {
//    private struct GroupDropDelegate: DropDelegate {
//        let group: Group
//        @Binding var draggedGroup: Group?
//        @Binding var dragOver: Bool
//        @Binding var dragOverPosition: DragPosition?
//        let onDrop: (Group, Group?, DragPosition) -> Void
//
//        // Estimated row height (8 padding top + 8 padding bottom + ~20 content = 36)
//        private let estimatedRowHeight: CGFloat = 36
//        private var threshold: CGFloat { estimatedRowHeight / 3 }
//
//        func validateDrop(info: DropInfo) -> Bool {
//            // Allow drop if we have a dragged group and it's not the same as target
//            guard let draggedGroup = draggedGroup else { return false }
//            return draggedGroup.id != group.id
//        }
//
//        func performDrop(info: DropInfo) -> Bool {
//            guard let draggedGroup = draggedGroup,
//                  draggedGroup.id != group.id else {
//                dragOver = false
//                dragOverPosition = nil
//                return false
//            }
//
//            let position = dragOverPosition ?? .on
//            onDrop(draggedGroup, group, position)
//            self.draggedGroup = nil
//            dragOver = false
//            dragOverPosition = nil
//            return true
//        }
//
//        func dropEntered(info: DropInfo) {
//            guard draggedGroup?.id != group.id else { return }
//            dragOver = true
//        }
//
//        func dropExited(info: DropInfo) {
//            dragOver = false
//            dragOverPosition = nil
//        }
//
//        func dropUpdated(info: DropInfo) -> DropProposal? {
//            guard draggedGroup?.id != group.id else {
//                return DropProposal(operation: .forbidden)
//            }
//
//            // The location.y is relative to the view, with 0 at top
//            let location = info.location
//
//            if location.y < threshold {
//                dragOverPosition = .before
//            } else if location.y > (estimatedRowHeight - threshold) {
//                dragOverPosition = .after
//            } else {
//                dragOverPosition = .on
//            }
//
//            return DropProposal(operation: .move)
//        }
//    }
//}

extension ManageView.Sidebar.GroupSection {
    struct Row: View {
        let row: SidebarViewModel.Row
        let icon: String?
        @Binding var dragging: SidebarViewModel.Row?
        let onToggleExpansion: () -> Void
        let onTap: () -> Void
        let onDrop: (UUID, UUID, DragPosition) -> Void
        let adjacent: (UUID, UUID) -> Bool
        private var height: CGFloat { Constant.rowHeight }
        
        @State private var dragPosition: DragPosition? = nil
        @State private var expandTask: Task<Void, Never>? = nil
        
        @EnvironmentObject var viewModel: SidebarViewModel
        
        var body: some View {
            HStack(alignment: .center, spacing: 6) {
                _leadingGap()
                Image(systemName: icon ?? (row.expanded ? "cube.fill" : (row.groupCount > 0 ? "cube.box.fill" : "cube.box")))
                    .font(.system(size: 16))
                    .frame(width: 16, height: 16, alignment: .center)
                    .foregroundStyle(.secondary)
                    .onTapGesture {
                        onTap()
                        guard row.groupCount > 0 else { return }
                        onToggleExpansion()
                    }
                
                // Group name
                Text(row.name)
                    .font(.system(size: 14))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                // Count
                Text(row.groupCount > 0 ? "\(row.bookmarkCount)/\(row.groupCount)" : "\(row.bookmarkCount)")
                    .font(.system(size: 13))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: Constant.cornerRadius)
                    .fill(backgroundColor)
            )
            .overlay(alignment: .top) {
                if let position = dragPosition {
                    switch position {
                    case .before:
                        _indicator1()
                            .offset(y: -(Constant.dragIndicatorHeight * 0.5))
                        // This allows the view to be larger than the parent
                        // without affecting the layout flow of the list
                            .allowsHitTesting(false)
                    case .in:
                        _indicator2(childCount: viewModel.effectiveChildrenCount(row.id))
                            .allowsHitTesting(false)
                    case .after:
                        
                        _indicator1()
                            .offset(y: height - Constant.dragIndicatorHeight * 0.5)
                            .allowsHitTesting(false)
                        
                    }
                }
            }
            .zIndex(dragPosition != nil ? 1 : 0)
            .onTapGesture {
                onTap()
            }
            .onDrag {
                dragging = row
                return NSItemProvider(object: row.id.uuidString as NSString)
            } preview: {
                // Drag preview
                HStack(spacing: 8) {
                    // TODO: reuse Image
                    Image(systemName: row.expanded ? "hexagon.fill" : (row.groupCount > 0 ? "cube.box.fill" : "cube.box"))
                        .font(.system(size: 16))
                        .frame(width: 16, height: 16, alignment: .center)
                        .foregroundStyle(.secondary)
                    Text(row.name)
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
                hostId: row.id,
                dragging: $dragging,
                dragPosition: $dragPosition,
                rowHeight: height,
                expanded: row.expanded,
                onDrop: onDrop,
                adjacent: adjacent
            ))
            .onChange(of: dragPosition) { oldValue, newValue in
                handleDragPositionChange(newValue)
            }
            
        }
        
        /// Handles auto-expand when hovering over an expandable item during drag
        private func handleDragPositionChange(_ position: DragPosition?) {
            expandTask?.cancel()
            expandTask = nil
            
            guard !row.expanded else { return }
            
            // Only start expand timer if:
            // 1. Position is .in (hovering over middle zone)
            // 2. The row has children (groupCount > 0)
            // 3. The row is not already expanded
            // 4. We're actually dragging something (not self)
            guard position == .in,
                  row.groupCount > 0,
                  let drag = dragging,
                  drag.id != row.id else {
                return
            }
            
            let delay: UInt64 = 2_000_000_000 // 0.7 seconds in nanoseconds
            
            // Start a delayed task to expand
            expandTask = Task {
                do {
                    try await Task.sleep(nanoseconds: delay)
                    // Check if still valid after delay
                    if !Task.isCancelled {
                        await MainActor.run {
                            onToggleExpansion()
                        }
                    }
                } catch {
                    // Task was cancelled, do nothing
                }
            }
        }
        
        private var backgroundColor: Color {
            return row.selected ? Color.accentColor.opacity(0.5) : Color.clear
        }
        
        private func _indicator1() -> some View {
            HStack(spacing: 0) {
                _leadingGap()
                Rectangle()
                    .fill(Color.accentColor)
            }
                .frame(height: Constant.dragIndicatorHeight)
            
        }
        
        private func _indicator2(childCount: Int) -> some View {
            RoundedRectangle(cornerRadius: Constant.cornerRadius)
                .fill(Color.clear)
                .stroke(Color.accentColor, lineWidth: Constant.dragIndicatorHeight)
                .frame(height: (Double(childCount) + 1) * height)
        }
        
        private func _leadingGap() -> some View {
            ForEach(0..<row.level, id: \.self) { _ in
                Spacer().frame(width: Constant.leadingGap)
            }
        }
        
        enum Constant {
            static let rowHeight: CGFloat = 36
            static let dragIndicatorHeight: CGFloat = 2
            static let cornerRadius: CGFloat = 6
            static let leadingGap: CGFloat = 16
        }
    }
}

extension ManageView.Sidebar.GroupSection {
    struct Dropper: SwiftUI.DropDelegate {
        let hostId: UUID
        @Binding var dragging: SidebarViewModel.Row?
        @Binding var dragPosition: DragPosition?
        let rowHeight: CGFloat
        let expanded: Bool
        let onDrop: (UUID, UUID, DragPosition) -> Void
        let adjacent: (UUID, UUID) -> Bool
        
        // Only before/after zones - middle zone is rejected
        private var threshold: CGFloat { rowHeight / 3 }
        
        func validateDrop(info: DropInfo) -> Bool {
            guard let drag = dragging else { return false }
            return drag.id != hostId
        }
        
        func performDrop(info: DropInfo) -> Bool {
            guard let drag = dragging,
                  drag.id != hostId,
                  let position = dragPosition else {
                reset()
                return false
            }
            
            onDrop(hostId, drag.id, position)
            self.dragging = nil
            reset()
            return true
        }
        
        func dropEntered(info: DropInfo) {
            guard dragging?.id != hostId else { return }
            _updatePosition(info)
        }
        
        func dropExited(info: DropInfo) {
            reset()
        }
        
        func dropUpdated(info: DropInfo) -> DropProposal? {
            guard dragging?.id != hostId else {
                return DropProposal(operation: .forbidden)
            }
            
            _updatePosition(info)
            return DropProposal(operation: .move)
        }
        
        private func reset() {
            dragPosition = nil
        }
        
        private func _updatePosition(_ info: DropInfo) {
            guard let drag = dragging else { return }
            guard !adjacent(hostId, drag.id) else { return }
            
            let location = info.location
            
            if expanded {
                dragPosition = .in
                return
            }
            
            if location.y < threshold {
                dragPosition = .before
            } else if location.y > (rowHeight - threshold) {
                dragPosition = .after
            } else {
                dragPosition = .in
            }
        }
    }
}

extension ManageView.Sidebar.GroupSection {
    enum DragPosition {
        case `in`
        case before
        case after
    }
}
