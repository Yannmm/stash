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
        
        
        var body: some View {
            if viewModel.rows.count > 0 {
                Section("Groups") {
                    ForEach(viewModel.rows, id: \.id) { row in
                        Row(
                            row: row,
                            dragging: $dragging,
                            onToggleExpansion: {
                                viewModel.toggleExpansion(row.id)
                            },
//                            draggingOne: $draggingOne,
//                            selectedOne: $selectedOne,
        
                            
//                            onDrop: { droppedGroup, targetGroup, position in
//                                handleDrop(droppedGroup: droppedGroup, targetGroup: targetGroup, position: position)
//                            },
                            onTap: {
                                viewModel.setSelection(row.id)
                            },
                            onDrop: { drag, over, insertAfter in
                                print("drag popsition: \(insertAfter)")
                            }
                        )
                    }
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
        @Binding var dragging: SidebarViewModel.Row?
        @State private var dragPosition: DragPosition? = nil
        let onToggleExpansion: () -> Void
        let onTap: () -> Void
        let onDrop: (SidebarViewModel.Row, SidebarViewModel.Row, DragPosition) -> Void
        private var height: CGFloat { 36 }
        
        
        var body: some View {
            HStack(spacing: 6) {
                ForEach(0..<row.level, id: \.self) { _ in
                    Spacer().frame(width: 16)
                }
                Image(systemName: row.expanded ? "hexagon.fill" : (row.groupCount > 0 ? "cube.box.fill" : "cube.box"))
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
                RoundedRectangle(cornerRadius: 6)
                    .fill(backgroundColor)
            )
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
                current: row,
                dragging: $dragging,
                dragPosition: $dragPosition,
                rowHeight: height,
                onDrop: onDrop
            ))

        }
        
        private var backgroundColor: Color {
//            if dragOver {
//                switch dragOverPosition {
//                case .before, .after:
//                    return Color.accentColor.opacity(0.15)
//                case .on:
//                    return Color.accentColor.opacity(0.2)
//                case .none:
//                    return Color.primary.opacity(0.05)
//                }
//            }
//            return row.selected ? Color.accentColor : Color.clear
            return Color.random
        }
    }
}

extension ManageView.Sidebar.GroupSection {
    struct Dropper: SwiftUI.DropDelegate {
        let current: SidebarViewModel.Row
        @Binding var dragging: SidebarViewModel.Row?
        @Binding var dragPosition: DragPosition?
        let rowHeight: CGFloat
        let onDrop: (SidebarViewModel.Row, SidebarViewModel.Row, DragPosition) -> Void
        
        // Only before/after zones - middle zone is rejected
        private var threshold: CGFloat { rowHeight / 3 }
        
        func validateDrop(info: DropInfo) -> Bool {
            guard let drag = dragging else { return false }
            return drag.id != current.id
        }
        
        func performDrop(info: DropInfo) -> Bool {
            guard let drag = dragging,
                  drag.id != current.id,
                  let position = dragPosition, position.within else {
                reset()
                return false
            }
            
            onDrop(drag, current, position)
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
                print("onnnn")
                dragPosition = .on
                return DropProposal(operation: .move)
            }
        }
        
        private func reset() {
            dragPosition = nil
        }
    }
}

extension ManageView.Sidebar.GroupSection {
    enum DragPosition {
        case over
        case on
        case before
        case after
        
        var within: Bool {
            switch self {
            case .on, .after, .before:
                return true
            default: return false
            }
        }
    }
}

fileprivate extension ManageView.WorkbenchView {
    enum Constant {
        static let rowHeight: CGFloat = 36
    }
}
