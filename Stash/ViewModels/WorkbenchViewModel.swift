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
            return _bookmarkCount(c.relatedEntries(allEntries))
        } else {
            return _bookmarkCount(allEntries)
        }
    }
    
    var groupCount: Int {
        if let c = collection {
            return _groupCount(c.relatedEntries(allEntries))
        } else {
            return _groupCount(allEntries)
        }
    }
    
    var rows: [Row] {
        let sublist = collection == nil ? allEntries : ((collection as? Group)?.children(among: allEntries) ?? [])
        let result = sublist.map {
            Row(id: $0.id,
                icon: $0.icon,
                title: $0.name,
                description: description($0),
                trail: trail($0) ,
                tags: $0.name.hashtags)
        }
        return result
    }
    
    private func _groupCount(_ entries: [any Entry]) -> Int {
        entries.compactMap({ $0 as? Group }).count
    }
    
    private func _bookmarkCount(_ entries: [any Entry]) -> Int {
        entries.compactMap({ $0 as? Bookmark }).count
    }
    
    private func trail(_ entry: any Entry) -> [String] {
        var trail = [Group]()
        
        var track = false
        
        var pid = entry.parentId
        while pid != nil {
            let group = allEntries.filter({ $0.id == pid }).compactMap({ $0 as? Group }).first
            pid = group?.parentId
            if let g = group  {
                if g.id == collection?.id {
                    track = true
                }
                guard track else { continue }
                trail.insert(g, at: 0)
            }
            
        }
        return trail.map { $0.name }
    }
    
    private func description(_ entry: any Entry) -> String {
        switch entry {
        case let b as Bookmark:
            return b.url.host() ?? b.url.absoluteString
        case let g as Group:
            let children = g.children(among: allEntries)
            let gcount = _groupCount(children)
            let bcount = _bookmarkCount(children)
            var result = "\(bcount) bookmarks"
            if gcount > 0 {
                result += " / \(gcount) groups"
            }
            return result
        default:
            return ""
        }
    }
}

extension WorkbenchViewModel {
    struct Row: Identifiable {
        let id: UUID
        let icon: Icon
        let title: String
        let description: String
        let trail: [String]
        let tags: [String]
    }
}
