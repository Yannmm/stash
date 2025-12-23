//
//  CollectionList.swift
//  Stash
//
//  Created by Yan Meng on 2025/12/16.
//

import SwiftUI
import UniformTypeIdentifiers

// A collection can be a group or hashtag
protocol Collection {
    
}


struct ManageViewSidebar: View {
    @Binding var selectedCollection: Collection?
    
    @State private var searchText = ""
    
    @Binding var groups: [Group]
    
    @Binding var hashtags: [Hashtag]
    
    private let tags = ClipTag.sampleData
    private let totalClips = 6
    
    var body: some View {
        VStack(spacing: 0) {
            // Traffic lights spacer
            HStack {
                Spacer()
                Button(action: {}) {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            // Search bar
            SearchBar(text: $searchText)
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    AllBookmarksRow(
                        count: totalClips,
                        selected: false,
                        onTap: {
//                            showAllClips = true
//                            selectedFolder = nil
//                            selectedTag = nil
                        }
                    )
                    GroupSection(groups: $groups)
                    TagSection(hashtags: $hashtags)
                }
                .padding(.horizontal, 16)
            }
            
            Spacer()
            
            // Footer
            FooterView()
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .background(Color(hex: 0x22242B))
    }
    
    
}

// MARK: - Search Bar

private struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.5))
            
            TextField("Search clips...", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.1))
        )
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white.opacity(0.5))
            .tracking(0.5)
    }
}

// MARK: - All Clips Row

extension ManageViewSidebar {
    private struct AllBookmarksRow: View {
        let count: Int
        let selected: Bool
        let onTap: () -> Void
        
        @State private var isHovered = false
        
        var body: some View {
            Button(action: onTap) {
                HStack(spacing: 10) {
                    Image(systemName: "infinity")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                    
                    Text("All Bookmarks")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Text("\(count)")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selected ? Color.white.opacity(0.15) : (isHovered ? Color.white.opacity(0.08) : Color.clear))
                )
            }
            .buttonStyle(.plain)
            .onHover { isHovered = $0 }
        }
    }
}

// MARK: - Groups Section
extension ManageViewSidebar {
    private struct GroupSection: View {
        @Binding var groups: [Group]
        @State private var expandedGroups: Set<UUID> = []
        @State private var draggedGroup: Group?
        
        var body: some View {
            if groups.count <= 0 {
                EmptyView()
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "GROUPS")
                    
                    VStack(spacing: 0) {
                        ForEach(rootGroups) { group in
                            GroupTreeNode(
                                group: group,
                                allGroups: groups,
                                level: 0,
                                isSelected: false,
                                expandedGroups: $expandedGroups,
                                draggedGroup: $draggedGroup,
                                onToggleExpand: { groupId in
                                    if expandedGroups.contains(groupId) {
                                        expandedGroups.remove(groupId)
                                    } else {
                                        expandedGroups.insert(groupId)
                                    }
                                },
                                onDrop: { droppedGroup, targetGroup, position in
                                    handleDrop(droppedGroup: droppedGroup, targetGroup: targetGroup, position: position)
                                },
                                action: {
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
        
        private var rootGroups: [Group] {
            groups.filter { $0.parentId == nil }
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
    private struct TagSection: View {
        @Binding var hashtags: [Hashtag]
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                // Tags Section
                SectionHeader(title: "TAGS")
                
                VStack(spacing: 0) {
                    ForEach(hashtags) { tag in
                        HashtagRow(
                            hashtag: tag,
                            isSelected: false,
                            action: {
//                                    selectedTag = tag
//                                    selectedFolder = nil
//                                    showAllClips = false
                            }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Group Tree Node

extension ManageViewSidebar {
    private struct GroupTreeNode: View {
        let group: Group
        let allGroups: [Group]
        let level: Int
        let isSelected: Bool
        @Binding var expandedGroups: Set<UUID>
        @Binding var draggedGroup: Group?
        let onToggleExpand: (UUID) -> Void
        let onDrop: (Group, Group?, DropPosition) -> Void
        let action: () -> Void
        
        @State private var isHovered = false
        @State private var dragOver = false
        @State private var dragOverPosition: DropPosition? = nil
        
        private var hasChildren: Bool {
            allGroups.contains { $0.parentId == group.id }
        }
        
        private var isExpanded: Bool {
            expandedGroups.contains(group.id)
        }
        
        private var children: [Group] {
            allGroups.filter { $0.parentId == group.id }
        }
        
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
                    
                    GroupRow(
                        group: group,
                        level: level,
                        isSelected: isSelected,
                        hasChildren: hasChildren,
                        isExpanded: isExpanded,
                        isHovered: isHovered,
                        dragOver: dragOver && dragOverPosition == .on,
                        dragOverPosition: dragOverPosition,
                        onToggleExpand: { onToggleExpand(group.id) },
                        action: action
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
                    draggedGroup = group
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
                    draggedGroup: $draggedGroup,
                    dragOver: $dragOver,
                    dragOverPosition: $dragOverPosition,
                    onDrop: onDrop
                ))
                .onHover { isHovered = $0 }
                
                if hasChildren && isExpanded {
                    ForEach(children) { child in
                        GroupTreeNode(
                            group: child,
                            allGroups: allGroups,
                            level: level + 1,
                            isSelected: false,
                            expandedGroups: $expandedGroups,
                            draggedGroup: $draggedGroup,
                            onToggleExpand: onToggleExpand,
                            onDrop: onDrop,
                            action: action
                        )
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

// MARK: - Folder Row

extension ManageViewSidebar {
    private struct GroupRow: View {
        let group: Group
        let level: Int
        let isSelected: Bool
        let hasChildren: Bool
        let isExpanded: Bool
        let isHovered: Bool
        let dragOver: Bool
        let dragOverPosition: DropPosition?
        let onToggleExpand: () -> Void
        let action: () -> Void
        
        var body: some View {
            HStack(spacing: 6) {
                // Indentation
                ForEach(0..<level, id: \.self) { _ in
                    Spacer()
                        .frame(width: 16)
                }
                
                // Expand/collapse button
                if hasChildren {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(width: 16, height: 16)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onToggleExpand()
                        }
                } else {
                    Spacer()
                        .frame(width: 16)
                }
                
                // Folder icon
                Image(systemName: "folder")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.7))
                
                // Group name
                Text(group.name)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.9))
                
                Spacer()
                
                // Count
                Text("22")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(backgroundColor)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                action()
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
            return isSelected ? Color.white.opacity(0.15) : (isHovered ? Color.white.opacity(0.08) : Color.clear)
        }
    }
}

// MARK: - Clip Tag Row

private struct HashtagRow: View {
    let hashtag: Hashtag
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text("#")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                
                Text(hashtag.name)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.9))
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.white.opacity(0.15) : (isHovered ? Color.white.opacity(0.08) : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Footer View

private struct FooterView: View {
    var body: some View {
        HStack {
            Text("Pro Account")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.5))
            
            Spacer()
            
            Text("70% used")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}


#Preview {
    let group1 = UUID()
    let group2 = UUID()
    let group3 = UUID()
    let child1 = UUID()
    let child2 = UUID()
    
    return ManageViewSidebar(
        selectedCollection: .constant(nil),
        groups: .constant([
            Group(id: group1, name: "Group 1", parentId: nil),
            Group(id: child1, name: "Child 1.1", parentId: group1),
            Group(id: child2, name: "Child 1.2", parentId: group1),
            Group(id: group2, name: "Group 2", parentId: nil),
            Group(id: group3, name: "Group 3", parentId: nil)
        ]),
        hashtags: .constant([
            Hashtag(name: "tag1"),
            Hashtag(name: "tag2"),
            Hashtag(name: "tag=3"),
        ])
    )
    .frame(width: 260, height: 700)
}
