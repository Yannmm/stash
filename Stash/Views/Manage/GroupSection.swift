//
//  GroupSection.swift
//  Stash
//
//  Created by Rayman on 2025/12/25.
//

import SwiftUI
import UniformTypeIdentifiers

extension ManageViewSidebar {
    struct GroupSection: View {
        @Binding var groups: [Group]
        @State private var expandedOnes: Set<UUID> = []
        @State private var draggingOne: Group?
        @State private var selectedOne: Group?
        
        private var roots: [Group] {
            groups.filter { $0.parentId == nil }
        }
        
        var body: some View {
            if groups.count <= 0 {
                EmptyView()
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "GROUPS")
                    
                    VStack(spacing: 0) {
                        ForEach(roots) { group in
                            Node(
                                group: group,
                                getChildren: { gid in groups.filter { $0.parentId == gid } },
                                checkExpanded: expandedOnes.contains,
                                level: 0,
                                draggingOne: $draggingOne,
                                selectedOne: $selectedOne,
                                onToggleExpansion: { groupId in
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        if expandedOnes.contains(groupId) {
                                            expandedOnes.remove(groupId)
                                        } else {
                                            expandedOnes.insert(groupId)
                                        }
                                    }
                                },
                                onDrop: { droppedGroup, targetGroup, position in
                                    handleDrop(droppedGroup: droppedGroup, targetGroup: targetGroup, position: position)
                                },
                                action: { group in
                                    selectedOne = group
                                    //                                    selectedFolder = group
                                    //                                    selectedTag = nil
                                    //                                    showAllClips = false
                                }
                            )
                        }
                    }
                }
            }
        }
        
        private func handleDrop(droppedGroup: Group, targetGroup: Group?, position: DropPosition) {
            guard let droppedIndex = groups.firstIndex(where: { $0.id == droppedGroup.id }) else { return }
            
            var updatedGroup = droppedGroup
            
            switch position {
            case .on:
                // Drop on target group (make it a child)
                updatedGroup.parentId = targetGroup?.id
            case .before, .after:
                // Drop before/after target group (same level as target)
                updatedGroup.parentId = targetGroup?.parentId
            }
            
            // Prevent dropping on itself
            if updatedGroup.parentId == updatedGroup.id {
                return
            }
            
            // Prevent circular references: check if the new parent is a descendant of the dragged group
            if let newParentId = updatedGroup.parentId,
               isDescendant(of: newParentId, ancestor: updatedGroup.id, in: groups) {
                return
            }
            
            // Create a new array to ensure SwiftUI detects the change
            var newGroups = groups
            
            // Remove the group from its current position
            newGroups.remove(at: droppedIndex)
            
            // Find the new insertion point
            if let targetGroup = targetGroup, let targetIndex = newGroups.firstIndex(where: { $0.id == targetGroup.id }) {
                let insertIndex: Int
                if position == .on {
                    // Insert at the end of the target's children
                    insertIndex = targetIndex + 1
                } else {
                    // Adjust target index based on position
                    insertIndex = position == .after ? targetIndex + 1 : targetIndex
                }
                let safeIndex = min(max(0, insertIndex), newGroups.count)
                newGroups.insert(updatedGroup, at: safeIndex)
            } else {
                // Dropping at root level, just append
                newGroups.append(updatedGroup)
            }
            
            // Assign the new array to trigger view update
            withAnimation(.easeInOut(duration: 0.2)) {
                groups = newGroups
            }
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
    
    enum DropPosition {
        case on
        case before
        case after
    }
}

extension ManageViewSidebar {
    private struct Node: View {
        let group: Group
        let getChildren: (UUID) -> [Group]
        let checkExpanded: (UUID) -> Bool
        let level: Int
        
        @Binding var draggingOne: Group?
        @Binding var selectedOne: Group?
        let onToggleExpansion: (UUID) -> Void
        let onDrop: (Group, Group?, DropPosition) -> Void
        let action: (Group) -> Void
        
        @State private var isHovered = false
        @State private var dragOver = false
        @State private var dragOverPosition: DropPosition? = nil
        
        var body: some View {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    // Drop indicator line (before)
                    if dragOver && dragOverPosition == .before {
                        Rectangle()
                            .fill(Color.accentColor)
                            .frame(height: 2)
                            .padding(.horizontal, 12 + CGFloat(level) * 16)
                    }
                    
                    Row(
                        group: group,
                        level: level,
                        getChildren: getChildren,
                        checkExpanded: checkExpanded,
                        isHovered: isHovered,
                        dragOver: dragOver && dragOverPosition == .on,
                        dragOverPosition: dragOverPosition,
                        onToggleExpansion: { onToggleExpansion(group.id) },
                        action: action,
                        selected: selectedOne?.id == group.id,
                    )
                    
                    // Drop indicator line (after)
                    if dragOver && dragOverPosition == .after {
                        Rectangle()
                            .fill(Color.accentColor)
                            .frame(height: 2)
                            .padding(.horizontal, 12 + CGFloat(level) * 16)
                    }
                }
                .contentShape(Rectangle())
                .onDrag {
                    draggingOne = group
                    return NSItemProvider(object: group.id.uuidString as NSString)
                } preview: {
                    // Drag preview
                    HStack(spacing: 8) {
                        Image(systemName: "folder")
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                        Text(group.name)
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(hex: 0x22242B).opacity(0.9))
                    .cornerRadius(6)
                }
                .onDrop(of: [UTType.plainText], delegate: GroupDropDelegate(
                    group: group,
                    draggedGroup: $draggingOne,
                    dragOver: $dragOver,
                    dragOverPosition: $dragOverPosition,
                    onDrop: onDrop
                ))
                .onHover { isHovered = $0 }
                
                if getChildren(group.id).count > 0 {
                    if checkExpanded(group.id) {
                        ForEach(getChildren(group.id)) { child in
                            Node(
                                group: child,
                                getChildren: getChildren,
                                checkExpanded: checkExpanded,
                                level: level + 1,
                                draggingOne: $draggingOne,
                                selectedOne: $selectedOne,
                                onToggleExpansion: onToggleExpansion,
                                onDrop: onDrop,
                                action: action,
                            )
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .top)),
                                removal: .opacity.combined(with: .move(edge: .top))
                            ))
                        }
                    }
                }
            }
        }
    }
    
    private struct GroupDropDelegate: DropDelegate {
        let group: Group
        @Binding var draggedGroup: Group?
        @Binding var dragOver: Bool
        @Binding var dragOverPosition: DropPosition?
        let onDrop: (Group, Group?, DropPosition) -> Void
        
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

extension ManageViewSidebar {
    private struct Row: View {
        let group: Group
        let level: Int
        let getChildren: (UUID) -> [Group]
        let checkExpanded: (UUID) -> Bool
        let isHovered: Bool
        let dragOver: Bool
        let dragOverPosition: DropPosition?
        let onToggleExpansion: () -> Void
        let action: (Group) -> Void
        let selected: Bool
        
        var body: some View {
            HStack(spacing: 6) {
                // Indentation
                ForEach(0..<level, id: \.self) { _ in
                    Spacer()
                        .frame(width: 16)
                }
                
                // Folder icon
                Image(systemName: (getChildren(group.id).count > 0 && !checkExpanded(group.id)) ? "folder.fill" : "folder")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.7))
                    .onTapGesture {
                        onToggleExpansion()
                    }
                
                // Group name
                Text(group.name)
                    .font(.system(size: 14))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(.white.opacity(0.9))
                
                Spacer()
                
                // Count
                Text("\(getChildren(group.id).count)")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 0)
                    .fill(backgroundColor)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                action(group)
            }
        }
        
        private var backgroundColor: Color {
            if dragOver {
                switch dragOverPosition {
                case .before, .after:
                    return Color.white.opacity(0.12)
                case .on:
                    return Color.white.opacity(0.15)
                case .none:
                    return Color.white.opacity(0.08)
                }
            }
            return selected ? Color.white.opacity(0.15) : (isHovered ? Color.white.opacity(0.08) : Color.clear)
        }
    }
}
