//
//  Toolbar.swift
//  Stash
//
//  Created by Rayman on 2026/2/6.
//

import SwiftUI

extension ManageView.WorkbenchView {
    struct Toolbar: View {
        @EnvironmentObject var viewModel: WorkbenchViewModel
        
        var body: some View {
            HStack(alignment: .top, spacing: 0) {
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
