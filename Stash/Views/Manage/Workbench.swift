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
    struct Workbench: View {
        @StateObject var viewModel: WorkbenchViewModel
        @State private var selection: UUID?
        
        var body: some View {
            Sheet(selection: $selection)
                .searchable(text: $viewModel.search, placement: .toolbar)
                .toolbar {
                    Toolbar(hierarchy: $viewModel.hierarchy,
                            title: viewModel.title,
                            groupCount: viewModel.groupCount,
                            bookmarkCount: viewModel.bookmarkCount,
                            hashtags: viewModel.hashtags,
                            hashtagFilter: $viewModel.hashtagFilter,
                            onAddBookmark: {},
                            onAddGroup: {})
                }
                .environmentObject(viewModel)
                .environmentObject(viewModel.dataStore)
        }
    }
}

struct RowFrameKey: PreferenceKey {
    static var defaultValue: [Int: Anchor<CGRect>] = [:]
    
    static func reduce(value: inout [Int: Anchor<CGRect>],
                       nextValue: () -> [Int: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

fileprivate extension ManageView.Workbench {
    private struct Sheet: View {
        @EnvironmentObject var viewModel: WorkbenchViewModel
        
        @Binding var selection: UUID?
        @State private var dragging: WorkbenchViewModel.Row?
        @State private var width1: CGFloat = Constant.initialWidth1
        @State private var width2: CGFloat = Constant.initialWidth2
        @State private var width3: CGFloat = Constant.initialWidth3
        
        @State private var indicating: (Int, DragPosition, UUID)?
        
        var body: some View {
            ZStack {
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
                                            onDrop: { id, subjectId, position in
                                                viewModel.move(subjectId, relativeTo: id, position: position)
                                                
                                                Task { @MainActor in
                                                    try? await Task.sleep(for: .milliseconds(250))
                                                    indicating = nil
                                                }
                                            },
                                            cascade: { id, subjectId in
                                                viewModel.cascade(from: subjectId, to: id)
                                            },
                                            indentColor: { index in
                                                viewModel.indentColor(index)
                                            },
                                            indicating: $indicating
                                        )
                                        .id(row.id)
                                        .anchorPreference(
                                            key: RowFrameKey.self,
                                            value: .bounds
                                        ) {
                                            [index: $0]
                                        }
                                    }
                                }
                            }
                            // Animate reorder even when `rows` is updated asynchronously via Combine.
                            .animation(.easeInOut(duration: 0.25), value: viewModel.rows.map(\.id))
                            Spacer(minLength: 0)
                        }
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
                .overlayPreferenceValue(RowFrameKey.self) { anchors in
                    GeometryReader { proxy in
                        if let index = indicating?.0,
                           let position = indicating?.1,
                           let id = indicating?.2,
                           let anchor = anchors[index] {
                            let frame = proxy[anchor]
                            switch position {
                            case .before:
                                _indicator1()
                                    .position(
                                        x: frame.midX,
                                        y: frame.minY
                                    )
                                    .zIndex(1)
                            case .after:
                                _indicator1()
                                    .position(
                                        x: frame.midX,
                                        y: frame.maxY
                                    )
                                    .zIndex(1)
                            case .in:
                                _indicator2(childCount: viewModel.strideCount(id))
                                    .frame(
                                        width: proxy.size.width,
                                        height: proxy.size.height,
                                        alignment: .topLeading
                                    )
                                    .offset(
                                        x: 0,
                                        y: frame.minY
                                    )
                                    .zIndex(1)
                            }
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
        }
        
        private func _indicator1() -> some View {
            Rectangle()
                .fill(Color.accentColor)
                .frame(height: Constant.dragIndicatorHeight)
                .allowsHitTesting(false)
            
        }
        
        private func _indicator2(childCount: Int) -> some View {
            Rectangle()
                .fill(Color.accentColor.opacity(0.3))
                .frame(height: (Double(childCount) + 1) * Constant.rowHeight)
                .allowsHitTesting(false)
        }
        
        private var totalWidth: CGFloat {
            width1 + width2 + width3 + Constant.resizerWidth * 2
        }
    }
}



// MARK: - Table Header

fileprivate extension ManageView.Workbench {
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

fileprivate extension ManageView.Workbench {
    struct Row: View {
        let index: Int
        let row: WorkbenchViewModel.Row
        @Binding var selection: UUID?
        @Binding var dragging: WorkbenchViewModel.Row?
        let width1: CGFloat
        let width2: CGFloat
        let totalWidth: CGFloat
        let onDrop: (UUID, UUID, DragPosition) -> Void
        let cascade: (UUID, UUID) -> Bool
        let indentColor: (Int) -> Color
        @Binding var indicating: (Int, DragPosition, UUID)?
        @State private var dragPosition: DragPosition? = nil
        private var hasIndicator: Bool { _propose(dragPosition)?.operation == .move }
        private var height: CGFloat { Constant.rowHeight }
        
        @State private var presentEditor = false
        
        var body: some View {
            HStack(spacing: 0) {
                // Name column
                IconAndNameCell(row: row, indentColor: indentColor)
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
                Text((row.tags ?? []).joined(separator: ", "))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: height)
            .frame(width: totalWidth, alignment: .leading)
            .background(backgroundColor)
            .focusable()
            .focusEffectDisabled()
            .onKeyPress(.return, action: {
                presentEditor = true
                return .handled
            })
            .popover(isPresented: $presentEditor) {
                EntryEditor()
                    .frame(width: 400)
                    .environmentObject(EntryEditorViewModel(mode: .update(row.id),
                                                            cabinet: OkamuraCabinet.shared,
                                                            dominator: Dominator()))
            }
            .onTapGesture { selection = row.id }
            .onDrag {
                dragging = row
                return NSItemProvider(object: row.id.uuidString as NSString)
            } preview: {
                HStack(spacing: 8) {
                    ViewHelper.icon(row.icon, side: 16)
                    Text(row.title)
                        .font(.system(size: 14))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.accentColor)
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
            .onChange(of: dragPosition) { _, newValue in
                if let position = newValue, hasIndicator {
                    indicating = (index, position, row.id)
                } else {
                    indicating = nil
                }
            }
        }
        
        private func _propose(_ position: DragPosition?) -> DropProposal? {
            guard let drag = dragging else { return nil }
            if cascade(row.id, drag.id) {
                return DropProposal(operation: .forbidden)
            }
            
            guard let p = position else {
                return nil
            }
            if row.expandable {
                return DropProposal(operation: .move)
            } else {
                switch p {
                case .before, .after:
                    return DropProposal(operation: .move)
                case .in:
                    return DropProposal(operation: .forbidden)
                }
            }
        }
        
        private var backgroundColor: Color {
            if selection == row.id {
                if indicating != nil {
                    return Color(nsColor: .unemphasizedSelectedContentBackgroundColor).opacity(0.8)
                }
                return Color(nsColor: .selectedContentBackgroundColor).opacity(0.8)
            }
            let colors = NSColor.alternatingContentBackgroundColors
            return Color(colors[index % colors.count])
        }
    }
}

fileprivate extension ManageView.Workbench {
    private struct IconAndNameCell: View {
        let row: WorkbenchViewModel.Row
        let indentColor: (Int) -> Color
        
        var body: some View {
            HStack(spacing: 0) {
                ForEach(0..<row.trail.count, id: \.self) { index in
                    Rectangle()
                        .frame(width: 1)
                        .frame(width: 12)
                        .frame(maxHeight: .infinity)
                        .foregroundColor(indentColor(index))
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

fileprivate extension ManageView.Workbench {
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

fileprivate extension ManageView.Workbench {
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
        
        static let dragIndicatorHeight: CGFloat = 2
        
        static let cornerRadius: CGFloat = 2
    }
}
