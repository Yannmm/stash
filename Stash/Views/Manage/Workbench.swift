//
//  BookmarkList.swift
//  Stash
//
//  Created by Yan Meng on 2025/12/16.
//

import SwiftUI
import AppKit
import Combine
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
                            parentId: viewModel.wrapper.selection,
                            onAddBookmark: {},
                            onAddGroup: {})
                }
                .environmentObject(viewModel)
                .environmentObject(viewModel.cabinet)
                .alert("Error", isPresented: Binding(
                    get: { viewModel.error != nil },
                    set: { if !$0 { viewModel.error = nil } }
                )) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(viewModel.error?.localizedDescription ?? "")
                }
                .onChange(of: viewModel.wrapper.selection) { _, _ in
                    selection = nil
                }
                .onChange(of: viewModel.hierarchy) { _, _ in
                    selection = nil
                }
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
        @State private var drag: WorkbenchViewModel.Row?
        @State private var width1: CGFloat = Constant.initialWidth1
        @State private var width2: CGFloat = Constant.initialWidth2
        @State private var width3: CGFloat = Constant.initialWidth3
        @State private var dragTarget: (Int, DragPosition, UUID)?
        
        @FocusState private var focusedRow: UUID?
        @FocusState private var focused: Bool
        
        private enum ScrollTarget {
            static let headerId = "workbench.header"
        }
        
        var body: some View {
            ZStack {
                GeometryReader { gproxy in
                    ScrollViewReader { sproxy in
                        ScrollView([.vertical, .horizontal]) {
                            VStack(spacing: 0) {
                                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                                    Section(
                                        header: Header(
                                            width1: $width1,
                                            width2: $width2,
                                            min1: Constant.minWidth1,
                                            min2: Constant.minWidth2,
                                            total: max(totalWidth, gproxy.size.width)
                                        )
                                        .id(ScrollTarget.headerId)
                                    )
                                    {
                                        ForEach(Array(viewModel.rows.enumerated()), id: \.element.id) { index, row in
                                            Row(
                                                index: index,
                                                row: row,
                                                selection: $selection,
                                                drag: $drag,
                                                focused: $focusedRow,
                                                width1: width1,
                                                width2: width2,
                                                totalWidth: max(totalWidth, gproxy.size.width),
                                                search: viewModel.search,
                                                onKeyboardNavigate: { direction in
                                                    navigate(direction)
                                                },
                                                onDrop: { id, subjectId, position in
                                                    viewModel.move(subjectId, relativeTo: id, position: position)
                                                    
                                                    Task { @MainActor in
                                                        try? await Task.sleep(for: .milliseconds(250))
                                                        dragTarget = nil
                                                    }
                                                },
                                                cascade: { id, subjectId in
                                                    viewModel.cascade(from: subjectId, to: id)
                                                },
                                                indentColor: { index in
                                                    viewModel.indentColor(index)
                                                },
                                                dragTarget: $dragTarget,
                                                onOpen: { viewModel.open($0) },
                                                onDelete: { viewModel.delete($0) },
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
                            .frame(minHeight: gproxy.size.height)
                        }
                        .focusable()
                        .focused($focused)
                        .focusEffectDisabled()
                        .onKeyPress(.downArrow, phases: [.down, .repeat], action: { result in
                            DispatchQueue.main.async {
                                navigate(.down)
                            }
                            return .handled
                        })
                        .onKeyPress(.upArrow, phases: [.down, .repeat], action: { result in
                            DispatchQueue.main.async {
                                navigate(.up)
                            }
                            return .handled
                        })
                        .onAppear {
                            if selection == nil {
                                focused = true
                            }
                        }
                        .onChange(of: selection) { _, newValue in
                            guard let id = newValue else {
                                focusedRow = nil
                                focused = true
                                return
                            }
                            focusedRow = id
                            focused = false
                            DispatchQueue.main.async {
                                withAnimation(.easeInOut(duration: 0.12)) {
                                    let ids = viewModel.rows.map(\.id)
                                    if id == ids.first {
                                        sproxy.scrollTo(ScrollTarget.headerId, anchor: .top)
                                    } else if id == ids.last {
                                        sproxy.scrollTo(id, anchor: .bottom)
                                    } else {
                                        sproxy.scrollTo(id)
                                    }
                                }
                            }
                        }
                    }
                    .onChange(of: gproxy.size.width) { _, newWidth in
                        let delta = newWidth - totalWidth
                        if delta != 0 {
                            let proposed = width1 + delta
                            width1 = max(Constant.minWidth1, proposed)
                        }
                    }
                }
                .overlayPreferenceValue(RowFrameKey.self) { anchors in
                    GeometryReader { proxy in
                        if let index = dragTarget?.0,
                           let position = dragTarget?.1,
                           let id = dragTarget?.2,
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
        
        private func navigate(_ direction: MoveCommandDirection) {
            let ids = viewModel.rows.map(\.id)
            guard !ids.isEmpty else { return }
            
            let currentIndex = selection.flatMap { id in
                ids.firstIndex(of: id)
            }
            
            let newIndex: Int
            switch direction {
            case .down:
                if let i = currentIndex {
                    newIndex = (i + 1) % ids.count
                } else {
                    newIndex = 0
                }
            case .up:
                if let i = currentIndex {
                    newIndex = (i - 1 + ids.count) % ids.count
                } else {
                    newIndex = ids.count - 1
                }
            default:
                return
            }
            
            let newId = ids[newIndex]
            if selection != newId {
                selection = newId
            }
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
        @Binding var drag: WorkbenchViewModel.Row?
        let focused: FocusState<UUID?>.Binding
        let width1: CGFloat
        let width2: CGFloat
        let totalWidth: CGFloat
        let search: String
        let onKeyboardNavigate: (MoveCommandDirection) -> Void
        let onDrop: (UUID, UUID, DragPosition) -> Void
        let cascade: (UUID, UUID) -> CascadeOrder
        let indentColor: (Int) -> Color
        @Binding var dragTarget: (Int, DragPosition, UUID)?
        let onOpen: (UUID) -> Void
        let onDelete: (UUID) -> Void
        @State private var dragPosition: DragPosition? = nil
        private var hasIndicator: Bool { _propose(dragPosition)?.operation == .move }
        private var height: CGFloat { Constant.rowHeight }
        
        @State private var presentEditor = false
        @State private var presentContextMenu = false
        @State private var presentDeletionAlert: Bool = false
        
        @EnvironmentObject var cabinet: OkamuraCabinet
        
        var body: some View {
            HStack(spacing: 0) {
                // Name column
                IconAndNameCell(row: row, search: search, indentColor: indentColor)
                    .frame(width: width1, alignment: .leading)
                
                Spacer()
                    .frame(width: Constant.resizerWidth)
                
                // Description column
                Text(row.description.emphasize(search) { attr in
                    attr.foregroundColor = .secondary
                    attr.font = .system(size: 14, weight: .medium)
                } highlightStyle: { attr, range in
                    attr[range].foregroundColor = .theme
                    attr[range].font = .system(size: 14, weight: .bold)
                })
                //                    .font(.system(size: 14, weight: .medium))
                //                    .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(width: width2, alignment: .leading)
                
                Spacer()
                    .frame(width: Constant.resizerWidth)
                
                Text((row.tags ?? []).joined(separator: ", ").emphasize(search) { attr in
                    attr.foregroundColor = .secondary
                    attr.font = .system(size: 14, weight: .medium)
                } highlightStyle: { attr, range in
                    attr[range].foregroundColor = .theme
                    attr[range].font = .system(size: 14, weight: .bold)
                })
                
                // Tags column
                //                    .font(.system(size: 14, weight: .medium))
                //                    .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: height)
            .frame(width: totalWidth, alignment: .leading)
            .background(backgroundColor)
            .overlay(
                // Outer border (white)
                Rectangle()
                    .strokeBorder(Color.clear, lineWidth: 1)
                    .opacity(presentContextMenu ? 1 : 0)
            )
            .overlay(
                // Inner border (red, inset)
                Rectangle()
                    .inset(by: 1) // 👈 match outer lineWidth
                    .strokeBorder(contextBorderColor2, lineWidth: 2)
                    .opacity(presentContextMenu ? 1 : 0)
            )
            .background(
                RightClickMonitorView {
                    presentContextMenu = true
                }
            )
            .focusable()
            .focused(focused, equals: row.id)
            .focusEffectDisabled()
            .help(row.extra)
            .onKeyPress(.return, action: {
                presentEditor = true
                return .handled
            })
            .onKeyPress(.space, action: {
                onOpen(row.id)
                return .handled
            })
            .onKeyPress(.downArrow, action: {
                onKeyboardNavigate(.down)
                return .handled
            })
            .onKeyPress(.upArrow, action: {
                onKeyboardNavigate(.up)
                return .handled
            })
            .popover(isPresented: $presentEditor) {
                SwiftUI.Group {
                    switch row.entryType {
                    case .bookmark:
                        BookmarkEditor(viewModel: BookmarkEditorViewModel(mode: .update(row.id),
                                                               cabinet: cabinet,
                                                               dominator: Dominator()))
                    case .directory:
                        GroupEditor(viewModel: GroupEditorViewModel(mode: .update(row.id), cabinet: cabinet))
                    }
                }
                .frame(width: 400)
            }
            .onDrag {
                drag = row
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
                drag: $drag,
                dragPosition: $dragPosition,
                rowHeight: height,
                expanded: row.expanded,
                onDrop: onDrop,
//                cascade: cascade,
                propose: _propose
            ))
            .onTapGesture {
                selection = row.id
                focused.wrappedValue = row.id
            }
            .contextMenu {
                Text(row.title)
                Text(row.extra)
                Divider()
                if row.actionable {
                    Button("Open") {
                        onOpen(row.id)
                    }
                }
                Button("Edit") {
                    selection = row.id
                    presentEditor = true
                }
                Divider()
                Button("Delete", role: .destructive) {
                    presentDeletionAlert = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSMenu.didEndTrackingNotification)) { _ in
                presentContextMenu = false
            }
            .onChange(of: presentEditor) { _, isPresented in
                guard !isPresented, selection == row.id else { return }
                // When the popover is dismissed (e.g. Esc), restore keyboard focus
                // so arrow-key navigation continues to work.
                focused.wrappedValue = nil
                DispatchQueue.main.async {
                    focused.wrappedValue = row.id
                }
            }
            .onChange(of: dragPosition) { _, newValue in
                if let position = newValue, hasIndicator {
                    dragTarget = (index, position, row.id)
                } else if row.id == dragTarget?.2 {
                    dragTarget = nil
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                if selection == row.id {
                    focused.wrappedValue = nil
                    DispatchQueue.main.async {
                        focused.wrappedValue = row.id
                    }
                }
            }
            .alert("Sure to delete \"\(row.title)\" ?", isPresented: $presentDeletionAlert, actions: {
                Button("Remove", role: .destructive) {
                    onDelete(row.id)
                }
            }, message: {
                Text("This action cannot be undone.")
            })
        }
        
        private func _propose(_ position: DragPosition?) -> DropProposal? {
            guard let position = position, let drag = drag else { return nil }
            
            switch cascade(row.id, drag.id) {
            case .none:
                if row.expandable {
                    return DropProposal(operation: .move)
                } else {
                    switch position {
                    case .before, .after:
                        return DropProposal(operation: .move)
                    case .in:
                        return DropProposal(operation: .forbidden)
                    }
                }
            case .up:
                return DropProposal(operation: .forbidden)
            case .down:
                switch(position) {
                case .before:
                    return DropProposal(operation: .move)
                case .in:
                    fallthrough
                case .after:
                    return DropProposal(operation: .forbidden)
                }
            }
        }
        
        private var backgroundColor: Color {
            if selection == row.id {
                if dragTarget != nil {
                    return Color(nsColor: .unemphasizedSelectedContentBackgroundColor).opacity(0.8)
                }
                return Color(nsColor: .selectedContentBackgroundColor).opacity(0.8)
            }
            let colors = NSColor.alternatingContentBackgroundColors
            return Color(colors[index % colors.count])
        }
        
        private var contextBorderColor1: Color {
            if selection == row.id {
                return Color.clear
            }
            return Color.accentColor
        }
        
        private var contextBorderColor2: Color {
            if selection == row.id {
                return Color.white
            }
            return Color.accentColor
        }
    }
}

fileprivate extension ManageView.Workbench {
    private struct IconAndNameCell: View {
        let row: WorkbenchViewModel.Row
        let search: String
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
                    Text(row.title.emphasize(search) { attr in
                        attr.foregroundColor = .primary
                        attr.font = .system(size: 14, weight: .medium)
                    } highlightStyle: { attr, range in
                        attr[range].foregroundColor = .theme
                        attr[range].font = .system(size: 14, weight: .bold)
                    })
                    //                        .font(.system(size: 14, weight: .medium))
                    //                        .foregroundStyle(.primary)
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
        static let initialWidth2: CGFloat = 260
        static let initialWidth3: CGFloat = 120
        static let minWidth1: CGFloat = 180
        static let minWidth2: CGFloat = 120
        
        static let leading1: CGFloat = 24
        static let gap1: CGFloat = 12
        static let iconWidth: CGFloat = 16
        
        static let dragIndicatorHeight: CGFloat = 2
        
        static let cornerRadius: CGFloat = 2
    }
}
