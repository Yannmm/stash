//
//  Dish.swift
//  Stash
//
//  Created by Rayman on 2025/2/10.
//

import Foundation

protocol Entry: Hashable, Identifiable, Equatable {
    var id: UUID { get }
    var name: String { get }
    var parentId: UUID? { get set }
    var icon: Icon { get }
    
    func open()
    func reveal()
    var children: [any Entry]? { get set }
}

extension Entry {
    var children: [any Entry]? {
        get { return nil }
        set { }
    }
}

extension Entry {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id.uuidString)
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Codable Support for Entry

// Type-erasing wrapper for Entry that conforms to Codable
struct AnyEntry: Codable {
    let id: UUID
    let name: String
    let parentId: UUID?
    let iconType: String
    let iconValue: String?
    let entryType: String
    let children: [AnyEntry]?
    
    // Additional properties for specific entry types
    let url: URL?
    
    enum CodingKeys: String, CodingKey {
        case id, name, parentId, iconType, iconValue, entryType, children, url
    }
    
    init(from entry: any Entry) {
        self.id = entry.id
        self.name = entry.name
        self.parentId = entry.parentId
        
        switch entry.icon {
        case .favicon(let url):
            self.iconType = "favicon"
            self.iconValue = url?.absoluteString
        case .system(let name):
            self.iconType = "system"
            self.iconValue = name
        }
        
        if let bookmark = entry as? Bookmark {
            self.entryType = "bookmark"
            self.url = bookmark.url
        } else if entry is Directory {
            self.entryType = "directory"
            self.url = nil
        } else {
            self.entryType = "unknown"
            self.url = nil
        }
        
        if let children = entry.children, !children.isEmpty {
            self.children = children.map { AnyEntry(from: $0) }
        } else {
            self.children = nil
        }
    }
    
    func toEntry() -> any Entry {
        let icon: Icon
        switch iconType {
        case "favicon":
            icon = .favicon(iconValue != nil ? URL(string: iconValue!) : nil)
        case "system":
            icon = .system(iconValue ?? "questionmark")
        default:
            icon = .system("questionmark")
        }
        
        switch entryType {
        case "bookmark":
            guard let url = url else {
                fatalError("Bookmark must have a URL")
            }
            var bookmark = Bookmark(id: id, name: name, url: url, icon: icon)
            bookmark.parentId = parentId
            
            if let children = children, !children.isEmpty {
                bookmark.children = children.map { $0.toEntry() }
            }
            
            return bookmark
            
        case "directory":
            var directory = Directory(id: id, name: name, icon: icon)
            directory.parentId = parentId
            
            if let children = children, !children.isEmpty {
                directory.children = children.map { $0.toEntry() }
            }
            
            return directory
            
        default:
            fatalError("Unknown entry type: \(entryType)")
        }
    }
}

// Extension to convert arrays of Entry to/from Codable format
extension Array where Element == any Entry {
    func toAnyEntries() -> [AnyEntry] {
        return self.map { AnyEntry(from: $0) }
    }
    
    static func fromAnyEntries(_ anyEntries: [AnyEntry]) -> [any Entry] {
        return anyEntries.map { $0.toEntry() }
    }
}

enum Icon {
    case favicon(URL?)
    case system(String)
}

extension Array<any Entry> {
    func findBy(id: UUID) -> (any Entry)? {
        return self
            .map { e in [[e], (e.children ?? [])].flatMap { $0 } }
            .flatMap { $0 }
            .first { $0.id == id }
    }
}
