//
//  AnyEntry.swift
//  Stash
//
//  Created by Yan Meng on 2025/3/19.
//

import Foundation

enum EntryType: Codable {
    case bookmark
    case directory
}


struct AnyEntry: Codable {
    let id: UUID
    let name: String
    let parentId: UUID?
    let icon: Icon
    let type: EntryType
    
    // For bookmark
    let url: URL?
    
    init(_ entry: any Entry) {
        self.id = entry.id
        self.name = entry.name
        self.parentId = entry.parentId
        self.icon = entry.icon
        
        switch entry {
        case let b as Bookmark:
            self.url = b.url
            self.type = .bookmark
        case let _ as Directory:
            self.url = nil
            self.type = .directory
        default:
            fatalError("Unexpected entry type")
        }
    }
    
    
    func asEntry() -> any Entry {
        switch type {
        case .bookmark:
            guard let url = url else {
                fatalError("Bookmark must have a URL")
            }
            return Bookmark(id: id, name: name, parentId: parentId, url: url)
        case .directory:
            return Directory(id: id, name: name, parentId: parentId)
        }
    }
}

extension Array where Element == any Entry {
    var asAnyEntries: [AnyEntry] {
        self.map { AnyEntry($0) }
    }
}

extension Array where Element == AnyEntry {
    var asEntries: [any Entry] {
        self.map { $0.asEntry() }
    }
}
