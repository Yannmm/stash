//
//  Combo.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/11.
//

import Foundation

/// Logical group
struct Group {
    var id: UUID
    var name: String
    var parentId: UUID?
}

extension Group: Entry {
    var icon: Icon { .system("square.stack.3d.down.right.fill") }
    
    var container: Bool { true }
    
    var shouldExpand: Bool { false }
    
    var height: CGFloat { CellView.Constant.groupHeight }
}

extension Group {
    var unboxable: Bool { true }
    
    func unbox() {
        print(11111123)
    }
}
