//
//  Combo.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/11.
//

import Foundation

class Directory {
    let id: UUID
    let title: String
    var children: [Entry]?
    var parent: Entry?
    
    init(id: UUID, title: String, children: [Entry], parentId: UUID? = nil) {
        self.id = id
        self.title = title
        self.children = children
        self.children?.forEach { $0.parent = self }
    }
}

extension Directory: Entry {

    
    var name: String {
        return title
    }
    
    func open() {
        print("打开目录（菜单中）")
    }
    
    func reveal() {
        print("不执行？")
    }
}
