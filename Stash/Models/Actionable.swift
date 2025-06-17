//
//  Actionable.swift
//  Stash
//
//  Created by Rayman on 2025/3/28.
//

import Foundation

protocol Actionable {
    var revealable: Bool { get }
    
    var copyable: Bool { get }
    
    var valueToCopy: String? { get }
    
    var unboxable: Bool { get }
    
    func open()
    
    func reveal()
    
//    func unbox()
}

extension Actionable {
    var revealable: Bool { false }
    
    var copyable: Bool { false }
    
    var valueToCopy: String? { nil }
    
    var unboxable: Bool { false }
    
    func open() {}
    
    func reveal() {}
    
//    func unbox() {}
}
