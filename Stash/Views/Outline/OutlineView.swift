//
//  Home.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/14.
//

import SwiftUI
import Cocoa

// MARK: - NSOutlineView Wrapper
struct OutlineView: NSViewRepresentable {
    @Binding var entries: [any Entry]
    @Binding var anchorId: UUID?
    @Binding var presentingModal: Bool
    
    @EnvironmentObject var cabinet: OkamuraCabinet
    
    let onSelectRow: (UUID?) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.contentInsets = .init(top: 0, left: 12, bottom: 0, right: 12)
        scrollView.hasVerticalScroller = true
        
        let outlineView = HierarchyView() {
            onSelectRow(nil)
        }
        outlineView.draggingDestinationFeedbackStyle = .regular
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Column"))
        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column
        outlineView.headerView = nil
        outlineView.autoresizesOutlineColumn = false
        outlineView.style = .plain
        
        outlineView.dataSource = context.coordinator
        outlineView.delegate = context.coordinator
        
        outlineView.registerForDraggedTypes([.string])
        outlineView.setDraggingSourceOperationMask(.move, forLocal: true)
        
        scrollView.documentView = outlineView
        
        outlineView.target = context.coordinator
        
        outlineView.doubleAction = #selector(context.coordinator.tableViewDoubleAction)
        
        NotificationCenter.default.addObserver(forName: .onCmdKeyChange, object: nil, queue: nil) { _ in
            
            var indices = [Int]()
            
            for (index, entry) in entries.enumerated() {
                if entry is Bookmark {
                    indices.append(index)
                }
            }
            
            outlineView.noteHeightOfRows(withIndexesChanged: IndexSet(indices))
        }
        
        NotificationCenter.default.addObserver(forName: NSControl.textDidEndEditingNotification, object: nil, queue: nil) { noti in
            guard let view = outlineView.window?.firstResponder as? NSView, view.isDescendant(of: outlineView) else { return }
            
            for index in 0..<outlineView.numberOfRows {
                let row = outlineView.rowView(atRow: index, makeIfNecessary: true) as! RowView
                row.isFocused = false
            }
        }
        
        return scrollView
    }
    
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        // TODO: combine id & parent id
        guard entries.map({$0.id.uuidString.suffix(4)}) != context.coordinator.parent.entries.map({$0.id.uuidString.suffix(4)})
                && entries
            .map({$0.parentId})
        !=
        context.coordinator.parent.entries
            .map({$0.parentId})
        else { return }
        
        print("🐶 --> \(entries.map({$0.id.uuidString.suffix(4)})) 🌞 \(context.coordinator.parent.entries.map({$0.id.uuidString.suffix(4)}))")
        context.coordinator.parent = self
        
        guard let outlineView = nsView.documentView as? NSOutlineView else { return }
        
        // TODO: checkout this article. https://chris.eidhof.nl/post/view-representable/
        DispatchQueue.main.async {
            outlineView.reloadData()
            _expandIfNecessary(outlineView)
        }
    }
    
    private func _expandIfNecessary(_ outlineView: NSOutlineView) {
        if let aid = anchorId,
           let entry1 = entries.findBy(id: aid),
           let lid = entry1.location,
           let entry2 = entries.findBy(id: lid) {
            outlineView.expandItem(entry2)
        }
    }
}

extension OutlineView {
    class Coordinator: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
        
        var parent: OutlineView
        
        init(parent: OutlineView) {
            self.parent = parent
        }
        
        @objc func tableViewDoubleAction(sender: AnyObject) {
            guard !NSEvent.modifierFlags.containsOnly(.command) else { return }
            
            let outlineView = sender as! NSOutlineView
            
            guard let entry = outlineView.item(atRow: outlineView.clickedRow) as? any Entry else { return }
            
            //            https://peterfriese.dev/blog/2021/swiftui-list-focus/
            // how to handle enter key event.
            outlineView.deselectRow(outlineView.clickedRow)
            
            let row = outlineView.rowView(atRow: outlineView.clickedRow, makeIfNecessary: true) as! RowView
            row.isFocused = true
            
            NotificationCenter.default.post(name: .onDoubleTapRowView, object: entry)
        }
        
        // MARK: - NSOutlineViewDataSource
        
        func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
            return (item as? any Entry)?.children(among: parent.entries).count ?? parent.entries.toppings().count
        }
        
        func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
            !((item as? any Entry)?.children(among: parent.entries) ?? []).isEmpty
        }
        
        func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
            if let e = item as? any Entry, let entry = parent.entries.findBy(id: e.id) {
                return entry.children(among: parent.entries)[index]
            }
            return parent.entries.toppings()[index]
        }
        
        // MARK: - NSOutlineViewDelegate
        
        //                https://stackoverflow.com/questions/9052127/nstableview-how-to-click-anywhere-in-the-cell-to-edit-text
        //                https://www.mattrajca.com/2016/02/17/handling-text-editing-in-view-based-nstableviews.html#:~:text=Historically%2C%20adding%20editing%20support%20to,called%20with%20the%20updated%20value.
        
        func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
            guard let entry = item as? any Entry else { return nil }
            
            let identifier = NSUserInterfaceItemIdentifier("Cell")
            var cell: CellView! = outlineView.makeView(withIdentifier: identifier, owner: self) as? CellView
            
            if cell == nil {
                cell = CellView()
                cell?.identifier = identifier
            }
            
            cell?.entry = entry
            return cell
        }
        
        func outlineView(_ outlineView: NSOutlineView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, byItem item: Any?) {
            print(item)
        }
        
        func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
            let row = RowView() { [weak self] in self?.parent.presentingModal ?? false }
            row.id = (item as? (any Entry))?.id
            return row
        }
        
        func outlineViewSelectionDidChange(_ notification: Notification) {
            guard let outlineView = notification.object as? NSOutlineView else { return }
            
            let entry = outlineView.item(atRow: outlineView.selectedRow) as? (any Entry)
            parent.onSelectRow(entry?.id)
            
            NotificationCenter.default.post(name: .onHoverRowView, object: (entry?.id, false))
        }
        
        // MARK: - Drag & Drop
        
        func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
            guard let entry = item as? any Entry else { return nil }
            let pasteboardItem = NSPasteboardItem()
            pasteboardItem.setString(entry.id.uuidString, forType: .string)
            return pasteboardItem
        }
        
        func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem: Any?, proposedChildIndex: Int) -> NSDragOperation {
            return .move
        }
        
        func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
            let view = NSHostingView(rootView: CellContent(viewModel: CellViewModel(entry: item as? any Entry), expanded: NSEvent.modifierFlags.containsOnly(.command))
                .frame(width: 600))
            return view.fittingSize.height
        }
        
        func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex: Int) -> Bool {
            guard let pasteboardItem = info.draggingPasteboard.pasteboardItems?.first,
                  let pid = pasteboardItem.string(forType: .string),
                  var draggedItem = findItem(by: pid, in: parent.entries) else { return false }
            
            // Begin updates for animation
            outlineView.beginUpdates()
            
            parent.entries.removeAll(where: { $0.id == draggedItem.id })
            
            var children = [any Entry]()
            if let targetParent = item as? any Entry {
                draggedItem.parentId = targetParent.id
                children = targetParent.children(among: parent.entries)
            } else {
                draggedItem.parentId = nil
                children = parent.entries.filter({ $0.parentId == nil })
            }
            
            if childIndex >= 0 && childIndex <= children.count, let index = parent.entries.firstIndex(where: { $0.id == children[childIndex].id }) {
                parent.entries.insert(draggedItem, at: index)
            } else {
                parent.entries.append(draggedItem)
            }
            
            // End updates
            outlineView.endUpdates()
            
            // TODO: copy entries and assign back to parent
            
            DispatchQueue.global().async { [weak self] in
                // TODO: handle error
                try? self?.parent.cabinet.save()
            }
            
            return true
        }
        
        private func findItem(by id: String, in items: [any Entry]) -> (any Entry)? {
            for item in items {
                if item.id.uuidString == id { return item }
                if let found = findItem(by: id, in: item.children(among: parent.entries)) {
                    return found
                }
            }
            return nil
        }
    }
}

fileprivate extension OutlineView {
    class HierarchyView: NSOutlineView {
        let onEscKeyDown: () -> Void
        
        init(onEscKeyDown: @escaping () -> Void) {
            self.onEscKeyDown = onEscKeyDown
            super.init(frame: CGRectZero)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func keyDown(with event: NSEvent) {
            if event.keyCode == 53 { // 53 = Esc key
                deselectAll(nil)
            } else {
                super.keyDown(with: event)
            }
        }
        
        override func frameOfOutlineCell(atRow row: Int) -> NSRect {
            var frame = super.frameOfOutlineCell(atRow: row)
            frame.origin.x += 10
            return frame
        }
    }
}




