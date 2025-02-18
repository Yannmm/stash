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
    @State var items: [Entry]
    
    func makeCoordinator() -> Coordinator {
        Coordinator(entries: items)
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
        // No need to update dynamically in this simple case
    }
}

extension OutlineView {
    class Coordinator: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
        var entries: [Entry]
        
        init(entries: [Entry]) {
            self.entries = entries
        }
        
        // MARK: - NSOutlineViewDataSource
        
        func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
            (item as? Entry)?.children?.count ?? entries.count
        }
        
        func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
            (item as? Entry)?.children != nil
        }
        
        func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
            if let listItem = item as? Entry {
                return listItem.children![index]
            }
            return entries[index]
        }
        
        // MARK: - NSOutlineViewDelegate
        
        func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
            guard let listItem = item as? Entry else { return nil }
            
            let identifier = NSUserInterfaceItemIdentifier("Cell")
            var cell = outlineView.makeView(withIdentifier: identifier, owner: self) as? CustomTableViewCell
            
            if cell == nil {
                cell = CustomTableViewCell()
                cell?.identifier = identifier
            }
            
            cell?.title = listItem.name
            return cell
        }
        
        // MARK: - Drag & Drop
        
        func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
            guard let listItem = item as? Entry else { return nil }
            let pasteboardItem = NSPasteboardItem()
            pasteboardItem.setString(listItem.id.uuidString, forType: .string)
            return pasteboardItem
        }
        
        func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem: Any?, proposedChildIndex: Int) -> NSDragOperation {
            return .move
        }
        
        func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
            let view = NSHostingView(rootView: CellContent(title: (item as! Entry).name))
            return view.intrinsicContentSize.height
        }
        
        func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex: Int) -> Bool {
            guard let pasteboardItem = info.draggingPasteboard.pasteboardItems?.first,
                  let itemID = pasteboardItem.string(forType: .string),
                  let draggedItem = findItem(by: itemID, in: entries) else { return false }
            
            let targetParent = item as? Entry
            
            // Begin updates for animation
            outlineView.beginUpdates()
            
            // Remove from old location
            if let oldParent = draggedItem.parent {
                if let index = oldParent.children?.firstIndex(where: { $0.id == draggedItem.id }) {
                    oldParent.children?.remove(at: index)
                    outlineView.removeItems(at: IndexSet(integer: index), inParent: oldParent, withAnimation: .slideLeft)
                }
            } else {
                if let index = entries.firstIndex(where: { $0.id == draggedItem.id }) {
                    entries.remove(at: index)
                    outlineView.removeItems(at: IndexSet(integer: index), inParent: nil, withAnimation: .slideLeft)
                }
            }
            
            // Insert at new location
            if let targetParent = targetParent {
                if targetParent.children == nil {
                    targetParent.children = []
                }
                let insertIndex = childIndex == -1 ? (targetParent.children?.count ?? 0) : childIndex
                targetParent.children?.insert(draggedItem, at: insertIndex)
                outlineView.insertItems(at: IndexSet(integer: insertIndex), inParent: targetParent, withAnimation: .slideRight)
                draggedItem.parent = targetParent
            } else {
                let insertIndex = (childIndex == -1 || childIndex >= entries.count) ? entries.endIndex : childIndex
                entries.insert(draggedItem, at: insertIndex)
                outlineView.insertItems(at: IndexSet(integer: insertIndex), inParent: nil, withAnimation: .slideRight)
                draggedItem.parent = nil
            }
            
            // End updates
            outlineView.endUpdates()
            
            return true
        }
        
        private func findItem(by id: String, in items: [Entry]) -> Entry? {
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




