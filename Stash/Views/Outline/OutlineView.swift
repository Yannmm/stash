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
    @Binding var items: [any Entry]
    
    @Binding var addFolder: Bool
    
    @FocusState var focusedReminder: Focusable?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(entries: $items, focus: $focusedReminder) {
            focusedReminder = .row(id: $0.id)
        }
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        
        let outlineView = HierarchyView()
        outlineView.draggingDestinationFeedbackStyle = .regular
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Column"))
        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column
        outlineView.headerView = nil
        
        outlineView.dataSource = context.coordinator
        outlineView.delegate = context.coordinator
        
        outlineView.registerForDraggedTypes([.string])
        outlineView.setDraggingSourceOperationMask(.move, forLocal: true)
        
        scrollView.documentView = outlineView
        
        outlineView.target = context.coordinator
        
        outlineView.doubleAction = #selector(context.coordinator.tableViewDoubleAction)
        
        return scrollView
    }
    
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let outline = nsView.documentView as? NSOutlineView else { return }
        
        
        if let outlineView = nsView.documentView as? NSOutlineView {
            for row in 0..<outlineView.numberOfRows {
                guard let rowView = outlineView.rowView(atRow: row, makeIfNecessary: false) as? RowView,
                      let item = outlineView.item(atRow: row) as? any Entry else { continue }
                
                // Update focus state based on focusedReminder
                if case .row(let id) = focusedReminder {
                    rowView.isFocused = (item.id == id)
                } else {
                    rowView.isFocused = false
                }
            }
        }
        
        
        let olds = context.coordinator.entries
        let news = items
        guard olds.count != news.count || !olds.elementsEqual(news, by: { $0.id == $1.id }) else {
            return
        }
        DispatchQueue.main.async {
            context.coordinator.entries = items
            outline.reloadData()
        }
    }
}

extension OutlineView {
    class Coordinator: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
        @Binding var entries: [any Entry]
        
        let onDoubleClick: (any Entry) -> Void
        var focus: FocusState<Focusable?>.Binding
        
        init(entries: Binding<[any Entry]>, focus: FocusState<Focusable?>.Binding, onDoubleClick: @escaping (any Entry) -> Void) {
            self._entries = entries
            self.focus = focus
            self.onDoubleClick = onDoubleClick
        }
        
        @objc func tableViewDoubleAction(sender: AnyObject) {
            let aa = sender as! NSOutlineView

            let e = entries[aa.clickedRow]
            
            //            https://peterfriese.dev/blog/2021/swiftui-list-focus/
            // how to handle enter key event.
            aa.deselectRow(aa.clickedRow)
            
            
            let row = aa.rowView(atRow: aa.clickedRow, makeIfNecessary: false) as! RowView
            row.isFocused = true
            
            self.onDoubleClick(e)
        }
        
        // MARK: - NSOutlineViewDataSource
        
        func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
            return (item as? any Entry)?.children?.count ?? entries.count
        }
        
        func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
            (item as? any Entry)?.children != nil
        }
        
        func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
            if let e = item as? any Entry, let entry = entries.findBy(id: e.id) {
                return entry.children![index]
            }
            return entries[index]
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
            guard let coordinator = outlineView.dataSource as? Coordinator else {
                return nil
            }
            
            cell?.energy = (entry, coordinator.focus)
            return cell
        }
        
        func outlineView(_ outlineView: NSOutlineView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, byItem item: Any?) {
            print(item)
        }
        
        var rows = [RowView]()
        
        func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
            let row = RowView()
            if let entry = item as? any Entry,
               case .row(let id) = focus.wrappedValue {
                row.isFocused = (entry.id == id)
            }
            
            return row
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
            let view = NSHostingView(rootView: CellContent(viewModel: CellViewModel(entry: item as? any Entry), focus: FocusState<Focusable?>().projectedValue))
            return view.intrinsicContentSize.height
        }
        
        func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex: Int) -> Bool {
            guard let pasteboardItem = info.draggingPasteboard.pasteboardItems?.first,
                  let pid = pasteboardItem.string(forType: .string),
                  var draggedItem = findItem(by: pid, in: entries) else { return false }
            
            // Begin updates for animation
            outlineView.beginUpdates()
            
            // Remove from old location
            if let parentId = draggedItem.parentId, var oldParent = entries.findBy(id: parentId) {
                if let index = oldParent.children?.firstIndex(where: { $0.id == draggedItem.id }) {
                    var children = oldParent.children
                    children?.remove(at: index)
                    oldParent.children = children
                    //                    outlineView.removeItems(at: IndexSet(integer: index), inParent: oldParent, withAnimation: .slideLeft)
                }
            } else {
                if let index = entries.firstIndex(where: { $0.id == draggedItem.id }) {
                    entries.remove(at: index)
                    //                    outlineView.removeItems(at: IndexSet(integer: index), inParent: nil, withAnimation: .slideLeft)
                }
            }
            
            // Insert at new location
            let targetParent = item as? any Entry
            
            if var targetParent = targetParent {
                var children = targetParent.children ?? []
                let insertIndex = childIndex == -1 ? children.count : childIndex
                //                children.removeAll { $0.id == draggedItem.id }
                //                children.insert(draggedItem, at: insertIndex)
                
                //                children = children.rearrange(element: draggedItem, to: insertIndex)
                
                let index = children.firstIndex { $0.id == draggedItem.id }
                
                if let i = index {
                    if insertIndex == i {
                        
                    } else {
                        let element = children[i]
                        children.insert(element, at: insertIndex)
                        children.remove(at: i)
                        
                    }
                } else {
                    children.append(draggedItem)
                    
                }
                
                
                targetParent.children = children
                
                draggedItem.parentId = targetParent.id
                
                entries.indices.filter { entries[$0].id == targetParent.id }
                    .forEach { entries[$0] = targetParent }
                //                outlineView.insertItems(at: IndexSet(integer: insertIndex), inParent: targetParent, withAnimation: .slideRight)
            } else {
                let insertIndex = (childIndex == -1 || childIndex >= entries.count) ? entries.endIndex : childIndex
                entries.insert(draggedItem, at: insertIndex)
                
                draggedItem.parentId = nil
                
                //                outlineView.insertItems(at: IndexSet(integer: insertIndex), inParent: nil, withAnimation: .slideRight)
            }
            
            // End updates
            outlineView.endUpdates()
            
            return true
        }
        
        private func findItem(by id: String, in items: [any Entry]) -> (any Entry)? {
            for item in items {
                if item.id.uuidString == id { return item }
                if let found = findItem(by: id, in: item.children ?? []) {
                    return found
                }
            }
            return nil
        }
    }
}

fileprivate extension OutlineView {
    class HierarchyView: NSOutlineView {
        //    override func makeView(withIdentifier identifier: NSUserInterfaceItemIdentifier, owner: Any?) -> NSView? {
        //        let view = super.makeView(withIdentifier: identifier, owner: owner)
        //
        //        if identifier == NSOutlineView.disclosureButtonIdentifier {
        //            if let btnView = view as? NSButton {
        //                btnView.image = NSImage(systemSymbolName: "chevron.forward", accessibilityDescription: nil)
        //                btnView.alternateImage = NSImage(systemSymbolName: "chevron.down", accessibilityDescription: nil)
        //
        //                // can set properties of the image like the size
        //                btnView.image?.size = NSSize(width: 30, height: 30)
        //                btnView.alternateImage?.size = NSSize(width: 30, height: 30)
        //            }
        //        }
        //        return view
        //    }
    }
}




