//
//  xxx.swift
//  Stash
//
//  Created by Rayman on 2026/1/12.
//

import Combine
import Foundation

class WorkbenchViewModel: ObservableObject {
    @Published var collection: Collectible?
    @Published var allEntries: [any Entry]
    @Published var filter = ""
    
    init(entries: [any Entry]) {
        self.allEntries = entries
    }
    
    var title: String {
        collection?.title ?? "All Bookmarks"
    }
    
    var bookmarkCount: Int {
        if let c = collection {
            return c.relatedEntries(allEntries).compactMap({ $0 as? Bookmark }).count
        } else {
            return allEntries.compactMap({ $0 as? Bookmark }).count
        }
    }
    
    var rows: [Row] {
        let sublist = collection == nil ? allEntries : ((collection as? Group)?.children(among: allEntries) ?? [])
        let result = sublist.map { Row(id: $0.id, icon: $0.icon, title: $0.name, trail: trail($0) , tags: $0.name.hashtags) }
        return result
    }
    
    func trail(_ entry: any Entry) -> [String] {
        var trail = [Group]()
        
        var pid = entry.parentId
        while pid != nil {
            let group = allEntries.filter({ $0.id == pid }).compactMap({ $0 as? Group }).first
            if let g = group  {
                trail.insert(g, at: 0)
            }
            pid = group?.parentId
        }
        return trail.map { $0.name }
    }
    
    var groupCount: Int {
        if let c = collection {
            return c.relatedEntries(allEntries).compactMap({ $0 as? Group }).count
        } else {
            return allEntries.compactMap({ $0 as? Group }).count
        }
    }
}

extension WorkbenchViewModel {
    struct Row: Identifiable {
        let id: UUID
        let icon: Icon
        let title: String
        let trail: [String]
        let tags: [String]
    }
}
