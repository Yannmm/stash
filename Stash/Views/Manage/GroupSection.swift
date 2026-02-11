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
                            onDrop: { id, subjectId, position in
                                viewModel.move(subjectId, relativeTo: id, position: position)
                                _version += 1
                            },
                            cascade: { id, subjectId in
                                viewModel.cascade(from: subjectId, to: id)
                            }
                        )
                        .id("\(row.id)-\(_version)")
                    }
                } header: {
                    SectionHeader(title: "Groups")
                }
            }
        }
    }
}

extension ManageView.Sidebar.GroupSection {
    struct Row: View {
        let row: SidebarViewModel.Row
        let icon: String?
        @Binding var dragging: SidebarViewModel.Row?
        let onToggleExpansion: () -> Void
        let onTap: () -> Void
        let onDrop: (UUID, UUID, DragPosition) -> Void
        let cascade: (UUID, UUID) -> Bool
        private var height: CGFloat { Constant.rowHeight }
        
        @State private var dragPosition: DragPosition? = nil
        private var hasIndicator: Bool { _propose(dragPosition)?.operation == .move }
        @State private var expandTask: Task<Void, Never>? = nil
        
        @EnvironmentObject var viewModel: SidebarViewModel
        
        var body: some View {
            HStack(alignment: .center, spacing: 0) {
                _leadingGap(row.level)
                Image(systemName: icon ?? (row.expanded ? "cube.fill" : (row.groupCount > 0 ? "cube.box.fill" : "cube.box")))
                    .font(.system(size: 16))
                    .frame(width: 16, height: 16, alignment: .center)
                    .foregroundStyle(.secondary)
                    .onTapGesture {
                        onTap()
                        guard row.groupCount > 0 else { return }
                        onToggleExpansion()
                    }
                Spacer()
                    .frame(width: 6)
                Text(row.name)
                    .font(.system(size: 14))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(.primary)
                Spacer()
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
                if hasIndicator {
                    switch dragPosition! {
                    case .before:
                        _indicator1()
                            .offset(y: -(Constant.dragIndicatorHeight * 0.5))
                            .allowsHitTesting(false)
                    case .in:
                        _indicator2(childCount: viewModel.strideCount(row.id))
                            .allowsHitTesting(false)
                    case .after:
                        _indicator1()
                            .offset(y: height - Constant.dragIndicatorHeight * 0.5)
                            .allowsHitTesting(false)
                        
                    }
                }
            }
            .zIndex(hasIndicator ? 1 : 0)
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
                id: row.id,
                dragging: $dragging,
                dragPosition: $dragPosition,
                rowHeight: height,
                expanded: row.expanded,
                onDrop: onDrop,
                cascade: cascade,
                propose: _propose
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
        
        private func _propose(_ position: DragPosition?) -> DropProposal? {
            guard let _ = position else {
                return nil
            }
            return DropProposal(operation: .move)
        }
        
        private var backgroundColor: Color {
            if hasIndicator {
                return Color.accentColor.opacity(0.1)
            }
            return row.selected ? Color.accentColor.opacity(0.6) : Color.clear
        }
        
        private func _indicator1() -> some View {
                Rectangle()
                    .fill(Color.accentColor)
                .frame(height: Constant.dragIndicatorHeight)
            
        }
        
        private func _indicator2(childCount: Int) -> some View {
            RoundedRectangle(cornerRadius: Constant.cornerRadius)
                .fill(Color.clear)
                .stroke(Color.accentColor, lineWidth: Constant.dragIndicatorHeight)
                .frame(height: (Double(childCount) + 1) * height)
        }
        
        private func _leadingGap(_ count: Int) -> some View {
            ForEach(0..<count, id: \.self) { _ in
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
