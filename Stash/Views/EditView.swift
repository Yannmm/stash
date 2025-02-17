//
//  Home.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/14.
//

import SwiftUI
import Cocoa

// MARK: - Data Model
//class ListItem: Identifiable {
//    let id = UUID()
//    let title: String
//    var children: [ListItem]?
//    weak var parent: ListItem? // Helps with reordering
//
//    init(title: String, children: [ListItem]? = nil) {
//        self.title = title
//        self.children = children
//        self.children?.forEach { $0.parent = self }
//    }
//}

// MARK: - NSOutlineView Wrapper
struct OutlineView: NSViewRepresentable {
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
                //                let tf = NSTextField(labelWithString: "")
                //                cell?.textField = tf
                //                cell?.textField?.frame = CGRect(x: 5, y: 2, width: 200, height: 20)
                //                cell?.addSubview(cell!.textField!)
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
//            let xxx = item as! Entry
//            let xxx1 = NSHostingView(rootView: Cool1(title: xxx.name))
//            let aaa = xxx1.intrinsicContentSize
//            return aaa.height
            return 100
        }
        
        func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex: Int) -> Bool {
            guard let pasteboardItem = info.draggingPasteboard.pasteboardItems?.first,
                  let itemID = pasteboardItem.string(forType: .string),
                  let draggedItem = findItem(by: itemID, in: entries) else { return false }
            
            let targetParent = item as? Entry
            
            if let oldParent = draggedItem.parent {
                oldParent.children?.removeAll { $0.id == draggedItem.id }
            } else {
                entries.removeAll { $0.id == draggedItem.id }
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
                    entries.append(draggedItem)
                } else {
                    entries.insert(draggedItem, at: childIndex)
                }
                draggedItem.parent = nil
            }
            
            outlineView.reloadData()
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
    
    @Binding var items: [Entry]
    
    func makeCoordinator() -> Coordinator {
        Coordinator(entries: kEntries)
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        
        let outlineView = HierarchyView()
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

class HierarchyView: NSOutlineView {
    override func makeView(withIdentifier identifier: NSUserInterfaceItemIdentifier, owner: Any?) -> NSView? {
        let view = super.makeView(withIdentifier: identifier, owner: owner)
        
        if identifier == NSOutlineView.disclosureButtonIdentifier {
            if let btnView = view as? NSButton {
                btnView.image = NSImage(systemSymbolName: "chevron.forward", accessibilityDescription: nil)
                btnView.alternateImage = NSImage(systemSymbolName: "chevron.down", accessibilityDescription: nil)
                
                // can set properties of the image like the size
                btnView.image?.size = NSSize(width: 50.0, height: 50.0)
                btnView.alternateImage?.size = NSSize(width: 50.0, height: 50.0)
            }
        }
        return view
    }
}

class CustomTableViewCell: NSTableCellView {
    
    var title: String = "" {
        didSet {
            xxx.rootView = Cool1(title: title)
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: CGRectZero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var xxx: NSHostingView<Cool1>!
    
    private func setup() {
        let content = NSHostingView(rootView: Cool1(title: ""))
        self.xxx = content
        content.sizingOptions = .minSize
        self.addSubview(content)
        
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: self.topAnchor),
            content.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            content.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }
    
//    private var trackingArea: NSTrackingArea!
//    
//    override func draw(_ dirtyRect: NSRect) {
//        super.draw(dirtyRect)
//        
//        NSColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.00).set()
//        
//        // mouse hover
//        if highlight {
//            let path = NSBezierPath(rect: bounds)
//            path.fill()
//        }
//        
//        // draw divider
//        let rect = NSRect(x: 0, y: bounds.height - 2, width: bounds.width, height: bounds.height)
//        let path = NSBezierPath(rect: rect)
//        path.fill()
//    }
//    
//    private var highlight = false {
//        didSet {
//            setNeedsDisplay(bounds)
//        }
//    }
//    
//    override func mouseEntered(with event: NSEvent) {
//        super.mouseEntered(with: event)
//        if !highlight {
//            highlight = true
//        }
//    }
//    
//    override func mouseExited(with event: NSEvent) {
//        super.mouseExited(with: event)
//        if highlight {
//            highlight = false
//        }
//    }
//    
//    override func updateTrackingAreas() {
//        super.updateTrackingAreas()
//        if (trackingArea != nil) {
//            self.removeTrackingArea(trackingArea)
//        }
//        
//        
//        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways]
//            let trackingArea = NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil)
//            self.addTrackingArea(trackingArea)
//    }
//    
//    deinit {
//        removeTrackingArea(trackingArea)
//    }
}


struct Cool1: View {
    let title: String
    
    var body: some View {
        HStack {
            Label(title, systemImage: "folder.fill")
                .font(.largeTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
//                .onTapGesture {
//                    print("123123")
//                }
        }
    }
}
