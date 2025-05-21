//
//  Dish.swift
//  Stash
//
//  Created by Rayman on 2025/2/10.
//

import Foundation

protocol Entry: Identifiable, Equatable, Hashable, Facade {
    var id: UUID { get }
    
    var name: String { get set }
    
    var parentId: UUID? { get set }
    
    var location: UUID? { get }
    
    var icon: Icon { get }
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
    func children(among list: [any Entry]) -> [any Entry] {
        return list.filter { $0.parentId == id }
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
