//
//  Actionable.swift
//  Stash
//
//  Created by Rayman on 2025/3/28.
//

import Foundation

protocol Actionable {
    var revealable: Bool { get }
    
    func open()
    
    func reveal()
}
