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
    
    func makeCoordinator() -> Coordinator {
        Coordinator(entries: $items)
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
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let outline = nsView.documentView as? NSOutlineView else { return }
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
        
        init(entries: Binding<[any Entry]>) {
            self._entries = entries
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
                print("aaa --> \(entry.children![index])")
                return entry.children![index]
            }
            print("xxx --> \(entries[index])")
            return entries[index]
        }
        
        // MARK: - NSOutlineViewDelegate
        
        func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
            guard let entry = item as? any Entry else { return nil }
            
            let identifier = NSUserInterfaceItemIdentifier("Cell")
            var cell = outlineView.makeView(withIdentifier: identifier, owner: self) as? CustomTableViewCell
            
            if cell == nil {
                cell = CustomTableViewCell()
                cell?.identifier = identifier
            }
            
            cell?.entry = entry
            return cell
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
            let view = NSHostingView(rootView: CellContent(entry: (item as? any Entry)))
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




