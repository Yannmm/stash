//
//  Home.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/14.
//

import SwiftUI
import Cocoa

// MARK: - Data Model
class ListItem: Identifiable {
    let id = UUID()
    let title: String
    var children: [ListItem]?
    weak var parent: ListItem? // Helps with reordering
    
    init(title: String, children: [ListItem]? = nil) {
        self.title = title
        self.children = children
        self.children?.forEach { $0.parent = self }
    }
}

// MARK: - NSOutlineView Wrapper
struct OutlineView: NSViewRepresentable {
    class Coordinator: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
        var parent: OutlineView

        init(parent: OutlineView) {
            self.parent = parent
        }

        // MARK: - NSOutlineViewDataSource

        func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
            (item as? ListItem)?.children?.count ?? parent.items.count
        }

        func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
            (item as? ListItem)?.children != nil
        }

        func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
            if let listItem = item as? ListItem {
                return listItem.children?[index] ?? ListItem(title: "Unknown")
            }
            return parent.items[index]
        }

        // MARK: - NSOutlineViewDelegate

        func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
            guard let listItem = item as? ListItem else { return nil }
            
            let identifier = NSUserInterfaceItemIdentifier("Cell")
            var cell = outlineView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView
            
            if cell == nil {
                cell = NSTableCellView()
                cell?.identifier = identifier
                let tf = NSTextField(labelWithString: "")
                cell?.textField = tf
                cell?.textField?.frame = CGRect(x: 5, y: 2, width: 200, height: 20)
                cell?.addSubview(cell!.textField!)
            }
            
            cell?.textField?.stringValue = listItem.title
            return cell
        }

        // MARK: - Drag & Drop

        func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
            guard let listItem = item as? ListItem else { return nil }
            let pasteboardItem = NSPasteboardItem()
            pasteboardItem.setString(listItem.id.uuidString, forType: .string)
            return pasteboardItem
        }

        func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem: Any?, proposedChildIndex: Int) -> NSDragOperation {
            return .move
        }

        func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex: Int) -> Bool {
            guard let pasteboardItem = info.draggingPasteboard.pasteboardItems?.first,
                  let itemID = pasteboardItem.string(forType: .string),
                  let draggedItem = findItem(by: itemID, in: parent.items) else { return false }

            let targetParent = item as? ListItem
            
            if let oldParent = draggedItem.parent {
                oldParent.children?.removeAll { $0.id == draggedItem.id }
            } else {
                parent.items.removeAll { $0.id == draggedItem.id }
            }

            if let targetParent = targetParent {
                if targetParent.children == nil {
                    targetParent.children = []
                }
                if childIndex == -1 {
                    targetParent.children?.append(draggedItem)
                } else {
                    targetParent.children?.insert(draggedItem, at: childIndex)
                }
                draggedItem.parent = targetParent
            } else {
                if childIndex == -1 {
                    parent.items.append(draggedItem)
                } else {
                    parent.items.insert(draggedItem, at: childIndex)
                }
                draggedItem.parent = nil
            }

            outlineView.reloadData()
            return true
        }

        private func findItem(by id: String, in items: [ListItem]) -> ListItem? {
            for item in items {
                if item.id.uuidString == id { return item }
                if let found = findItem(by: id, in: item.children ?? []) {
                    return found
                }
            }
            return nil
        }
    }

    @Binding var items: [ListItem]

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        
        let outlineView = NSOutlineView()
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Column"))
        column.title = "Sections & Items"
        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column
        outlineView.headerView = nil
        
        outlineView.dataSource = context.coordinator
        outlineView.delegate = context.coordinator
        
        outlineView.registerForDraggedTypes([.string])
        outlineView.setDraggingSourceOperationMask(.move, forLocal: true)

        let tableContainer = NSScrollView()
        tableContainer.documentView = outlineView
        scrollView.documentView = tableContainer.documentView
        
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        // No need to update dynamically in this simple case
    }
}

