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
    
    var bookmarks: [Bookmark] {
        let entries = collection == nil ? entries : ((collection as? Group)?.children(among: entries) ?? [])
        return entries.compactMap({ $0 as? Bookmark })
    }
    
    var groupCount: Int {
        if let c = collection {
            return c.relatedEntries(entries).compactMap({ $0 as? Group }).count
        } else {
            return entries.compactMap({ $0 as? Group }).count
        }
    }
}
