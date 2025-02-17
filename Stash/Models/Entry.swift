//
//  Dish.swift
//  Stash
//
//  Created by Rayman on 2025/2/10.
//

import Foundation

protocol Entry: AnyObject {
    var name: String { get }
    var parent: Entry? { get set }
    
    var id: UUID { get }
    func open()
    func reveal()
    var children: [Entry]? { get set }
}

extension Entry {
    var children: [Entry]? {
        return nil
    }
}
