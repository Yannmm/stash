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
        @EnvironmentObject var viewModel: GroupSectionViewModel
        @State private var drag: Group?
        
        
        var body: some View {
            if viewModel.rows.count > 0 {
                Section("Groups") {
                    ForEach(Array(viewModel.rows.enumerated()), id: \.element.id) { index, row in
                        Row(
                            row: row,
//                            draggingOne: $draggingOne,
//                            selectedOne: $selectedOne,
        
                            
//                            onDrop: { droppedGroup, targetGroup, position in
//                                handleDrop(droppedGroup: droppedGroup, targetGroup: targetGroup, position: position)
//                            },
                            action: { group in
//                                viewModel.selection = group
                            },
                            selected: false
                        )
                        .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
                        .listRowSeparator(.hidden)
                    }
                }
            }
        }
        
        private func handleDrop(droppedGroup: Group, targetGroup: Group?, position: DragPosition) {
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
        
        private func isDescendant(of groupId: UUID, ancestor: UUID, in groups: [Group]) -> Bool {
            guard let group = groups.first(where: { $0.id == groupId }),
                  let parentId = group.parentId else {
                return false
            }
            if parentId == ancestor {
                return true
            }
            return isDescendant(of: parentId, ancestor: ancestor, in: groups)
        }
    }
    
    enum DragPosition {
        case on
        case before
        case after
    }
}

extension ManageView.Sidebar {
    private struct NodeRow: View {
        let group: Group
        let level: Int
        let getChildren: (UUID) -> [Group]
        let isExpanded: Bool
        
        @Binding var draggingOne: Group?
        @Binding var selectedOne: Group?
        let onToggleExpansion: () -> Void
        let onDrop: (Group, Group?, DragPosition) -> Void
        let action: (Group) -> Void
        
        @State private var dragOver = false
        @State private var dragOverPosition: DragPosition? = nil
        
        var body: some View {
            VStack(spacing: 0) {

//                Row(
//                    group: group,
//                    level: level,
//                    getChildren: getChildren,
//                    isExpanded: isExpanded,
//                    dragOver: dragOver && dragOverPosition == .on,
//                    dragOverPosition: dragOverPosition,
//                    onToggleExpansion: onToggleExpansion,
//                    action: action,
//                    selected: selectedOne?.id == group.id
//                )
            }
            .contentShape(Rectangle())
        }
    }
    
    private struct GroupDropDelegate: DropDelegate {
        let group: Group
        @Binding var draggedGroup: Group?
        @Binding var dragOver: Bool
        @Binding var dragOverPosition: DragPosition?
        let onDrop: (Group, Group?, DragPosition) -> Void
        
        // Estimated row height (8 padding top + 8 padding bottom + ~20 content = 36)
        private let estimatedRowHeight: CGFloat = 36
        private var threshold: CGFloat { estimatedRowHeight / 3 }
        
        func validateDrop(info: DropInfo) -> Bool {
            // Allow drop if we have a dragged group and it's not the same as target
            guard let draggedGroup = draggedGroup else { return false }
            return draggedGroup.id != group.id
        }
        
        func performDrop(info: DropInfo) -> Bool {
            guard let draggedGroup = draggedGroup,
                  draggedGroup.id != group.id else {
                dragOver = false
                dragOverPosition = nil
                return false
            }
            
            let position = dragOverPosition ?? .on
            onDrop(draggedGroup, group, position)
            self.draggedGroup = nil
            dragOver = false
            dragOverPosition = nil
            return true
        }
        
        func dropEntered(info: DropInfo) {
            guard draggedGroup?.id != group.id else { return }
            dragOver = true
        }
        
        func dropExited(info: DropInfo) {
            dragOver = false
            dragOverPosition = nil
        }
        
        func dropUpdated(info: DropInfo) -> DropProposal? {
            guard draggedGroup?.id != group.id else {
                return DropProposal(operation: .forbidden)
            }
            
            // The location.y is relative to the view, with 0 at top
            let location = info.location
            
            if location.y < threshold {
                dragOverPosition = .before
            } else if location.y > (estimatedRowHeight - threshold) {
                dragOverPosition = .after
            } else {
                dragOverPosition = .on
            }
            
            return DropProposal(operation: .move)
        }
    }
}

extension ManageView.Sidebar {
    private struct Row: View {
        let row: GroupSectionViewModel.Row
//        let dragOver: Bool
//        let dragOverPosition: DragPosition?
        let action: (Group) -> Void
        let selected: Bool
        
        
//        private var bookmarkCount: Int { group.children(among: .storedEntries).bookmarks.count }
        private var bookmarkCount: Int { 321 }
        
        
        
        var body: some View {
            HStack(spacing: 6) {
                // Indentation
                ForEach(0..<row.level, id: \.self) { _ in
                    Spacer()
                        .frame(width: 16)
                }
                
                // Folder icon
                Image(systemName: (groupCount > 0 && !row.expanded) ? "folder.fill" : "folder")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .onTapGesture {
//                        onToggleExpansion()
                    }
                
                // Group name
                Text(group.name)
                    .font(.system(size: 14))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                // Count
                Text(groupCount > 0 ? "\(bookmarkCount)/\(groupCount)" : "\(bookmarkCount)")
                    .font(.system(size: 13))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(backgroundColor)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                action(group)
            }
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
//            return selected ? Color.accentColor.opacity(0.2) : Color.clear
            return  Color.clear
        }
    }
}
