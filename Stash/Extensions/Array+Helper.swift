//
//  Array+Helper.swift
//  Stash
//
//  Created by Rayman on 2025/3/3.
//

import Foundation

extension Array {
    func rearrange(from oldIndex: Int, to newIndex: Int) -> Array<Self.Element> {
        var arr = self
        let element = arr.remove(at: oldIndex)
        arr.insert(element, at: newIndex)

        return arr
    }
    
    func rearrange(element: Self.Element, to newIndex: Int) -> Array<Self.Element> where Self.Element: Entry {
        var arr = self
        let index = arr.firstIndex { $0.id == element.id }
        
        if let i = index {
            if newIndex == i {
                return self
            } else {
                let element = self[i]
                arr.insert(element, at: newIndex)
                arr.remove(at: i)
                return arr
            }
        } else {
            arr.append(element)
            return arr
        }
    }
}
