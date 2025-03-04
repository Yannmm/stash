//
//  Dish.swift
//  Stash
//
//  Created by Rayman on 2025/2/10.
//

import Foundation

protocol Entry: Identifiable, Equatable, Codable {
    var id: UUID { get }
    var name: String { get }
    var parentId: UUID? { get set }
    var icon: Icon { get }
    
    func open()
    func reveal()
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
}

// ---------------------

struct AnyEntry: Codable {
    let base: any Entry

    init(_ base: any Entry) {
        self.base = base
    }

    func encode(to encoder: Encoder) throws {
        try base.encode(to: encoder)
    }

    init(from decoder: Decoder) throws {
        int
    }
}
