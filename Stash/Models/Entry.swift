//
//  Dish.swift
//  Stash
//
//  Created by Rayman on 2025/2/10.
//

import Foundation

protocol Entry: AnyObject, Identifiable {
    var id: UUID { get }
    var name: String { get }
    var parent: (any Entry)? { get set }
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


enum Icon {
    case favicon(URL?)
    case system(String)
}
