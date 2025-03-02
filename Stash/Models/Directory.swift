//
//  Combo.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/11.
//

import Foundation

struct Directory: Identifiable {
    let id: UUID
    let title: String
    var children: [any Entry]?
    var parentId: UUID?
}

extension Directory: Entry {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Directory, rhs: Directory) -> Bool {
        return lhs.id == rhs.id
    }

    var name: String {
        return title
    }
    
    var icon: Icon {
        return Icon.system("folder.fill")
    }
    
    func open() {
        print("打开目录（菜单中）")
    }
    
    func reveal() {
        print("不执行？")
    }
}
