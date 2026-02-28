//
//  AnyEntry.swift
//  Stash
//
//  Created by Yan Meng on 2025/3/19.
//

import Foundation
import OrderedCollections

enum EntryType: String, Codable {
    case bookmark
    case directory
}


struct AnyEntry: Codable {
    let id: UUID
    let name: String
    let type: EntryType
    let url: URL?
    let hashtags: Array<String>?
    var children: [AnyEntry]
    
    // TODO: parse hashtags from title
//    xxxxx
    init(id: UUID?, name: String, type: EntryType, url: URL?, hashtags: Array<String>, children: [AnyEntry]) {
        self.id = id ?? UUID()
        self.name = name
        self.type = type
        self.url = url
        self.hashtags = hashtags
        self.children = children
    }
    
    // TODO: parse hashtags from title
    init(_ entry: any Entry) {
        self.id = entry.id
        self.name = entry.name
        self.hashtags = entry.hashtags.flatMap({ Array($0) })
        self.children = []
        
        switch entry {
        case let b as Bookmark:
            self.url = b.url
            self.type = .bookmark
        case let _ as Group:
            self.url = nil
            self.type = .directory
        default:
            fatalError("Unexpected entry type")
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, url, hashtags, children
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decodeIfPresent(UUID.self, forKey: .id)) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(EntryType.self, forKey: .type)
        url = try container.decodeIfPresent(URL.self, forKey: .url)
        hashtags = try container.decodeIfPresent(Array<String>.self, forKey: .hashtags)
        children = try container.decodeIfPresent([AnyEntry].self, forKey: .children) ?? []
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.type, forKey: .type)
        try container.encodeIfPresent(self.url, forKey: .url)
        if !(self.hashtags?.isEmpty ?? true) {
            try container.encode(self.hashtags, forKey: .hashtags)
        }
        if self.children.count > 0 {
            try container.encode(self.children, forKey: .children)
        }
    }
}

extension AnyEntry {
    func asEntry(with parentId: UUID?) -> any Entry {
        switch self.type {
        case .bookmark:
            return Bookmark(id: id, name: name, parentId: parentId, url: url!, hashtags: hashtags.flatMap({ OrderedSet($0) }))
        case .directory:
            return Group(id: id, name: name, parentId: parentId, hashtags: hashtags.flatMap({ OrderedSet($0) }))
        }
    }
}

extension Array where Element == any Entry {
    var asAnyEntries: [AnyEntry] {
        func _inflate(target: inout [AnyEntry], source: [String: [any Entry]], key: String) {
            target.append(contentsOf: (source[key] ?? []).map { AnyEntry($0) })
            guard target.count > 0 else { return }
            for (index, value) in target.enumerated() {
                _inflate(target: &target[index].children, source: source, key: value.id.uuidString)
            }
        }
        
        
        var mapper = [String: [any Entry]]()
        
        self.forEach { entry in
            let key = entry.parentId?.uuidString ?? "?"
            var a = mapper[key] ?? []
            a.append(entry)
            mapper[key] = a
        }
        
        var result = [AnyEntry]()
        
        _inflate(target: &result, source: mapper, key: "?")
        
        return result
    }
}

extension Array where Element == AnyEntry {
    var asEntries: [any Entry] {
        func _deflate(target: inout [any Entry], source: [AnyEntry], parentId: UUID?) {
            for anyEntry in source {
                target.append(anyEntry.asEntry(with: parentId))
                _deflate(target: &target, source: anyEntry.children, parentId: anyEntry.id)
            }
        }
        
        var result = [any Entry]()
        
        _deflate(target: &result, source: self, parentId: nil)
        
        return result
    }
}
