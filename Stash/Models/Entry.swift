//
//  Dish.swift
//  Stash
//
//  Created by Rayman on 2025/2/10.
//

import Foundation

protocol Entry: Hashable, Identifiable {
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
        return nil
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
