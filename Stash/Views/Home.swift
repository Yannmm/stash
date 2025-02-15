//
//  Home.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/14.
//

import SwiftUI

import CoreTransferable

import UniformTypeIdentifiers

import AppKit

import SwiftUI
import AppKit
import UniformTypeIdentifiers

import Cocoa

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

//struct SelectionView_Previews: PreviewProvider {
//    static var previews: some View {
//        SelectionView(selectionViewModel: .init())
//    }
//}

//struct Profile: Codable, Identifiable {
////    typealias Representation = <#type#>
//    
//    var id: UUID = UUID()
//    var name: String
//    var phoneNumber: String
//    
//    
//}
//
//extension Profile: Transferable {
//    static var transferRepresentation: some TransferRepresentation {
//        CodableRepresentation(contentType: .appleScript)
//        ProxyRepresentation(exporting: \.name)
//    }
//}
//
//struct Home: View {
//    @State private var profiles = [
//        Profile(name: "Juan Chavez", phoneNumber: "(408) 555-4301"),
//        Profile(name: "Mei Chen", phoneNumber: "(919) 555-2481"),
//        Profile(name: "CCCC", phoneNumber: "(408) 555-4301"),
//        Profile(name: "EEEE", phoneNumber: "(919) 555-2481"),
//        Profile(name: "KKKK", phoneNumber: "(408) 555-4301"),
//        Profile(name: "AAAAA", phoneNumber: "(919) 555-2481")
//    ]
//    
//    var body: some View {
//        List {
//            ForEach(profiles.indices) { i in
//                Text(profile.name)
//                   .draggable(profile)
//            }.onMove { indices, newOffset in
//                // Update the items array based on source and destination indices.
//                profiles.move(fromOffsets: indices, toOffset: newOffset)
//            }
//            Section(header: Text("Important tasks")) {
//
//                        }
//            Section(header: Text("Important tasks")) {
//                ForEach(profiles) { profile in
//                    Text(profile.name)
//                       .draggable(profile)
//                }.onMove { indices, newOffset in
//                    // Update the items array based on source and destination indices.
//                    profiles.move(fromOffsets: indices, toOffset: newOffset)
//                }
//                        }
//        }
//    }
//}

//struct Home: View {
//    @State private var todo: [Task] = [
//        .init(title: "Edit Video", status: .todo)
//    ]
//    
//    @State private var working: [Task] = [
//        .init(title: "Record Video", status: .working)
//    ]
//    
//    @State private var completed: [Task] = [
//        .init(title: "implement Drag & Drop", status: .completed),
//        .init(title: "Update mock view app!", status: .completed)
//    ]
//    
//    /// View properties
//    @State private var currentlyDragging: Task?
//    var body: some View {
//        
//             HStack(spacing: 2) {
//                 TodoView()
//                 WorkingView()
//                 CompletedView()
//             }
//        
//    }
//    
//    @ViewBuilder
//    func TodoView() -> some View {
//        NavigationStack {
//            ScrollView(.vertical) {
//                TasksView(todo)
//            }
//            .navigationTitle("Todo")
//            .frame(maxWidth: .infinity)
//            .background(.ultraThinMaterial)
//        }
//    }
//    
//    @ViewBuilder
//    func TasksView(_ tasks: [Task]) -> some View {
//        VStack(alignment: .leading, spacing: 10) {
//            ForEach(tasks) { task in
//                GeometryReader {
//                    /// Task Row
//                    TaskRow(task, $0.size)
//                }
//                .frame(height: 45)
//            }
//        }
//        .frame(maxWidth: .infinity)
//        .padding()
//        
//    }
//    
//    @ViewBuilder
//    func TaskRow(_ task: Task, _ size: CGSize) -> some View {
//        Text(task.title)
//            .font(.callout)
//            .padding(.horizontal, 15)
//            .frame(maxWidth: .infinity, alignment: .leading)
//            .frame(height: size.height)
//            .background(.white, in: .rect(cornerRadius: 10))
//            .contentShape(.dragPreview, .rect(cornerRadius: 10))
//            .draggable(task.id.uuidString) {
////                Text(task.title)
////                    .font(.callout)
////                    .padding(.horizontal, 15)
////                    .frame(maxWidth: .infinity, alignment: .leading)
////                    .frame(height: size.height)
////                    .background(.white)
////                    .contentShape(.dragPreview, .rect(cornerRadius: 10))
//                RoundedRectangle(cornerRadius: 10)
//                                    .frame(width: 300, height: 300)
//                                    .foregroundStyle(.yellow.gradient)
//                                    .onAppear {
//                                        print("🐶 -- on appear called")
//                                        currentlyDragging = task
//                                    }
//            }
//            .dropDestination(for: String.self) { items, location in
//                currentlyDragging = nil
//                return false
//            } isTargeted: { status in
//                if let currentlyDragging, status, currentlyDragging.id != task.id {
//                    withAnimation(.snappy) {
//                        switch task.status {
//                        case .todo:
//                            replaceItem(tasks: &todo, droppingTask: task, status: .todo)
//                        case .working:
//                            replaceItem(tasks: &working, droppingTask: task, status: .working)
//                        case .completed:
//                            replaceItem(tasks: &completed, droppingTask: task, status: .completed)
//                        }
//                    }
//                }
//            }
//    }
//    
//    private func replaceItem(tasks: inout [Task], droppingTask: Task, status: Status) {
//        if let currentlyDragging {
//            if let sourceIndex = tasks.firstIndex(where: { t in
//                t.id == currentlyDragging.id
//            }), let destinationIndex = tasks.firstIndex(where: { $0.id ==  droppingTask.id}) {
//                /// Swapping
//                var sourceItem = tasks.remove(at: sourceIndex)
//                sourceItem.status = status
//                tasks.insert(sourceItem, at: destinationIndex)
//            }
//        }
//    }
//    
//    @ViewBuilder
//    func WorkingView() -> some View {
//        NavigationStack {
//
//            ScrollView(.vertical) {
//                TasksView(working)
//            }
//            .navigationTitle("Working")
//            .frame(maxWidth: .infinity)
//            .background(.ultraThinMaterial)
//        }
//    }
//    
//    @ViewBuilder
//    func CompletedView() -> some View {
//        NavigationStack {
//            ScrollView(.vertical) {
//                TasksView(completed)
//            }
//            .navigationTitle("Completed")
//            .frame(maxWidth: .infinity)
//            .background(.ultraThinMaterial)
//        }
//    }
//}
//
//#Preview {
//    ContentView()
//}
