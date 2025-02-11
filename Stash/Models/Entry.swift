//
//  Dish.swift
//  Stash
//
//  Created by Rayman on 2025/2/10.
//

import Foundation

protocol Entry {
    var name: String { get }
    
    func open()
    
    func reveal()
    
    var entries: [Entry] { get }
}

extension Entry {
    var entries: [Entry] {
        return []
    }
}
