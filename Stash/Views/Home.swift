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

struct Home: View {
    var numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

    var body: some View {
        GeometryReader { proxy in
            GridView(self.numbers, proxy: proxy) { number in
                Image("image\(number)")
                    .resizable()
                    .scaledToFill()
            }
        }
    }
}

struct GridView<CellView: View>: NSViewRepresentable {
    let cellView: (Int) -> CellView
    let proxy: GeometryProxy
    var numbers: [Int]

    init(_ numbers: [Int], proxy: GeometryProxy, @ViewBuilder cellView: @escaping (Int) -> CellView) {
        self.proxy = proxy
        self.cellView = cellView
        self.numbers = numbers
    }

    func makeNSView(context: Context) -> NSCollectionView {
        let layout = NSCollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.itemSize = CGSize(width: (proxy.size.width - 8) / 3, height: (proxy.size.width - 8) / 3)

        let collectionView = NSCollectionView()
        collectionView.collectionViewLayout = layout
        collectionView.register(GridCellView.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier("CELL"))

        collectionView.dataSource = context.coordinator
        collectionView.delegate = context.coordinator

        let scrollView = NSScrollView()
        scrollView.documentView = collectionView
        scrollView.hasVerticalScroller = true

        collectionView.isSelectable = true
        collectionView.allowsMultipleSelection = false
        collectionView.registerForDraggedTypes([.string])

        return collectionView
    }

    func updateNSView(_ nsView: NSCollectionView, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSCollectionViewDelegateFlowLayout, NSCollectionViewDataSource {
        var parent: GridView

        init(_ parent: GridView) {
            self.parent = parent
        }

        func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
            return parent.numbers.count
        }

        func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
            let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier("CELL"), for: indexPath) as! GridCellView
            item.view.layer?.backgroundColor = NSColor.clear.cgColor
            item.cellView.rootView = AnyView(parent.cellView(parent.numbers[indexPath.item]).fixedSize())
            return item
        }

        // MARK: - Drag & Drop
        func collectionView(_ collectionView: NSCollectionView, pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting? {
            let item = parent.numbers[indexPath.item]
            let pasteboardItem = NSPasteboardItem()
            pasteboardItem.setString("\(item)", forType: .string)
            return pasteboardItem
        }

        func collectionView(_ collectionView: NSCollectionView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forItemsAt indexPaths: Set<IndexPath>) {
            session.draggingPasteboard.setData(Data(), forType: .string)
        }

        func collectionView(_ collectionView: NSCollectionView, validateDrop info: NSDraggingInfo, proposedIndexPath: AutoreleasingUnsafeMutablePointer<IndexPath>, dropOperation: UnsafeMutablePointer<NSCollectionView.DropOperation>) -> NSDragOperation {
            return .move
        }

        func collectionView(_ collectionView: NSCollectionView, acceptDrop info: NSDraggingInfo, indexPath: IndexPath, dropOperation: NSCollectionView.DropOperation) -> Bool {
            guard let sourceIndex = info.draggingPasteboard.string(forType: .string).flatMap(Int.init),
                  let sourceItemIndex = parent.numbers.firstIndex(of: sourceIndex) else { return false }

            collectionView.performBatchUpdates({
                parent.numbers.remove(at: sourceItemIndex)
                parent.numbers.insert(sourceIndex, at: indexPath.item)
                collectionView.moveItem(at: IndexPath(item: sourceItemIndex, section: 0), to: indexPath)
            }, completionHandler: nil)

            return true
        }
    }
}

// MARK: - NSCollectionView Item (macOS Equivalent of UICollectionViewCell)
class GridCellView: NSCollectionViewItem {
    public var cellView = NSHostingController(rootView: AnyView(EmptyView()))

    override func loadView() {
        self.view = NSView()
        configure()
    }

    private func configure() {
        view.addSubview(cellView.view)
        cellView.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            cellView.view.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 5),
            cellView.view.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -5),
            cellView.view.topAnchor.constraint(equalTo: view.topAnchor, constant: 5),
            cellView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -5),
        ])

        cellView.view.layer?.masksToBounds = true
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
