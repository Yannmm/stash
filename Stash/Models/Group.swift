//
//  Combo.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/11.
//

import Foundation

/// Logical group
struct Group {
    let id: UUID
    var name: String
    var parentId: UUID?
}

extension Group: Entry {
    var icon: Icon {
        return .system("square.stack.3d.down.right.fill")
    }
    
    var shouldExpand: Bool { false }
    
    var height: CGFloat { CellView.Constant.groupHeight }
}
