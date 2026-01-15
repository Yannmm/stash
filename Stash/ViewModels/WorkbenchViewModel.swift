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
    @Published var filter = ""
    
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
    
    var bookmarks: [Bookmark] {
        let sublist = collection == nil ? entries : ((collection as? Group)?.children(among: entries) ?? [])
        let result = sublist.compactMap({ $0 as? Bookmark })
        return result
    }
    
    func trail(_ bookmark: Bookmark) -> [String] {
        var trail = [Group]()
        
        var pid = bookmark.parentId
        while pid != nil {
            let group = entries.filter({ $0.id == pid }).compactMap({ $0 as? Group }).first
            if let g = group  {
                trail.insert(g, at: 0)
            }
            pid = group?.parentId
        }
        return trail.map { $0.name }
    }
    
    var groupCount: Int {
        if let c = collection {
            return c.relatedEntries(entries).compactMap({ $0 as? Group }).count
        } else {
            return entries.compactMap({ $0 as? Group }).count
        }
    }
}
