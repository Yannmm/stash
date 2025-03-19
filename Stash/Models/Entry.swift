//
//  Dish.swift
//  Stash
//
//  Created by Rayman on 2025/2/10.
//

import Foundation

protocol Entry: Identifiable, Equatable, Hashable {
    var id: UUID { get }
    
    var name: String { get set }
    
    var parentId: UUID? { get set }
    
    var location: UUID? { get }
    
    var icon: Icon { get }
    
    func open()
    
    func reveal()
}

extension Entry {
    // TODO: remove this. make array flat.
    var children: [any Entry]? {
        get { return nil }
        set { }
    }
    
    var location: UUID? {
        switch self {
        case let b as  Bookmark:
            return b.parentId
        case let d as Directory:
            return d.id
        default:
            return nil
        }
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

enum Icon: Codable {
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
    
    func findChildrenBy(id: UUID?) -> [any Entry] {
        return self.filter { $0.parentId == id }
    }
}
