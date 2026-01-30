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
    func descendants(among entries: [any Entry], parent included: Bool = false) -> [any Entry] {
        var result: [any Entry] = []
        let directChildren = children(among: entries)
        result.append(contentsOf: directChildren)
        
        // Recursively get descendants of each child
        for (index, child) in directChildren.enumerated() {
            result.insert(contentsOf: child.descendants(among: entries), at: index + 1)
        }
        
        if included {
            result.insert(self, at: 0)
            return result
        } else {
            return result
        }
    }
    
    func siblings(among list: [any Entry]) -> [any Entry] {
        return list.filter { $0.parentId == parentId }
    }
}

extension Optional where Wrapped: Entry {
    func children(among entries: [any Entry]) -> [any Entry] {
        switch self {
        case .some(let value):
            value.children(among: entries)
        case .none:
            entries.filter { $0.parentId == nil }
        }
    }
    
    func descendants(among entries: [any Entry], parent included: Bool = false) -> [any Entry] {
        switch self {
        case .some(let value):
            return value.descendants(among: entries, parent: included)
        case .none:
            var result: [any Entry] = []
            for child in entries.filter({ $0.parentId == nil }) {
                result.append(contentsOf: child.descendants(among: entries, parent: true))
            }
            return result
        }
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
