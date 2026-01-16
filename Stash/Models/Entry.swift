//
//  Dish.swift
//  Stash
//
//  Created by Rayman on 2025/2/10.
//

import Foundation

protocol Entry: Identifiable, Equatable, Hashable, Facade, Actionable {
    var id: UUID { get set }
    
    var name: String { get set }
    
    var parentId: UUID? { get set }
    
    var location: UUID? { get }
    
    var icon: Icon { get }
    
    var container: Bool { get }
}

extension Entry {
    var location: UUID? {
        switch self {
        case let b as  Bookmark:
            return b.parentId
        case let g as Group:
            return g.id
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

extension Entry {
    // Direct children
    func children(among entries: [any Entry]) -> [any Entry] {
        return entries.filter { $0.parentId == id }
    }
    
    // All children below
    func descendants(among entries: [any Entry]) -> [any Entry] {
        func xxx(_ a: [any Entry]) -> [any Entry] {
            if a.isEmpty {
                return 
            }
        }
    }
    
    func siblings(among list: [any Entry]) -> [any Entry] {
        return list.filter { $0.parentId == parentId }
    }
}

extension Array<any Entry> {
    func findBy(id: UUID) -> (any Entry)? {
        return self.first { $0.id == id }
    }
    
    func toppings() -> [any Entry] {
        return self.filter { $0.parentId == nil }
    }
}

extension Array<any Entry> {
    var groups: [Group] { compactMap { $0 as? Group } }
    
    var bookmarks: [Bookmark] { compactMap { $0 as? Bookmark } }
}
