//
//  xxx.swift
//  Stash
//
//  Created by Rayman on 2026/1/12.
//

import Combine
import Foundation
import SwiftUI

class WorkbenchViewModel: ObservableObject {
    @Published var collection: Collectible?
    @Published var allEntries: [any Entry]
    @Published var filter = ""
    @Published var hierarchy: Hierarchy = .direct
    
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
        let result = heirs().map {
            Row(id: $0.id,
                icon: $0.icon,
                title: $0.name,
                description: description($0),
                trail: trail($0) ,
                tags: $0.name.hashtags)
        }
        return result
    }
    
    private func heirs() -> [any Entry] {
        switch hierarchy {
        case .direct:
            return (collection as? Group).children(among: allEntries)
        case .descendant:
            return (collection as? Group).descendants(among: allEntries)
        }
    }
    
    private func _groupCount(_ entries: [any Entry]) -> Int {
        entries.compactMap({ $0 as? Group }).count
    }
    
    private func _bookmarkCount(_ entries: [any Entry]) -> Int {
        entries.compactMap({ $0 as? Bookmark }).count
    }
    
    private func trail(_ entry: any Entry) -> [Group] {
        var trail = [Group]()
        var pid = entry.parentId
        while pid != nil {
            let group = allEntries.filter({ $0.id == pid }).compactMap({ $0 as? Group }).first
            if (pid == collection?.id) {
                break
            }
            if let g = group  {
                trail.append(g)
            }
            pid = group?.parentId
        }
        return trail
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
        let trail: [Group]
        let tags: [String]
    }
}

extension WorkbenchViewModel {
    enum Hierarchy {
        case direct
        case descendant
    }
}

extension WorkbenchViewModel {    
    /// Move an entry from source position to before/after target position
    func moveRow(_ subjectId: UUID, to destinationId: UUID, insertAfter: Bool) {
        // Find indices in allEntries
        guard let subjectIndex = allEntries.firstIndex(where: { $0.id == subjectId }),
              let destinationIndex = allEntries.firstIndex(where: { $0.id == destinationId }),
              subjectIndex != destinationIndex else {
            return
        }
        
        // Get the entry to move
        var subject = allEntries[subjectIndex]
        
        // Create new array with source removed
        var copies = allEntries
        copies.remove(at: subjectIndex)
        
        let destination = allEntries[destinationIndex]
        subject.parentId = destination.parentId
        
        // Calculate new target index (adjusted after removal)
        var newIndex = copies.firstIndex(where: { $0.id == destinationId }) ?? 0
        
        // Adjust based on drop position
        if insertAfter {
            newIndex += 1
        }
        
        // Ensure index is valid
        newIndex = min(max(0, newIndex), copies.count)
        
        // Insert at new position
        copies.insert(subject, at: newIndex)
                
        allEntries = copies
    }
}
