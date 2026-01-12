//
//  xxx.swift
//  Stash
//
//  Created by Rayman on 2026/1/12.
//

import Combine

class WorkbenchViewModel: ObservableObject {
    @Published var collection: Collectible?
    @Published var entries: [any Entry]
    
    init(entries: [any Entry]) {
        self.entries = entries
    }
    
    var title: String {
        collection?.title ?? "All Bookmarks"
    }
    
    var bookmarkCount: Int {
        if let c = collection {
            return c.relatedEntries(entries).compactMap({ $0 as? Bookmark }).count
        } else {
            return entries.compactMap({ $0 as? Bookmark }).count
        }
    }
    
    var groupCount: Int {
        if let c = collection {
            return c.relatedEntries(entries).compactMap({ $0 as? Group }).count
        } else {
            return entries.compactMap({ $0 as? Group }).count
        }
    }
    
//    @Published var entry: (any Entry)?
//    @Published var title: String
//    @Published var error: Error?
//    

//    
//    private var cancellables = Set<AnyCancellable>()
//    
//    var ableToUngroup: Bool {
//        if let e = entry, e.unboxable, e.children(among: cabinet.storedEntries).count > 0 {
//            return true
//        }
//        return false
//    }
//    
//    init(entry: (any Entry)? = nil, cabinet: OkamuraCabinet) {
//        self.cabinet = cabinet
//        self.entry = entry
//        self.title = entry?.name ?? ""
//        
//        bind()
//    }
//    
//    private func bind() {
//        $error
//            .compactMap({ $0 })
//            .sink { ErrorTracker.shared.add($0)}
//            .store(in: &cancellables)
//    }
//    
//    func update() throws {
//        guard var e = entry else { return }
//        guard e.name != title else { return }
//        if title.trim().isEmpty { title = e.name }
//        e.name = title
//        try cabinet.update(entry: e)
//        entry = e
//    }
//    
//    func ungroup(_ entry: any Entry) throws {
//        try cabinet.ungroup(entry: entry)
//    }
}
