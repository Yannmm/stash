//
//  Combo.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/11.
//

import Foundation

struct Directory {
    let id: UUID
    let name: String
    var parentId: UUID?
    let icon: Icon
    var children: [any Entry]?
    
    init(id: UUID, name: String, icon: Icon = .system("folder")) {
        self.id = id
        self.name = name
        self.icon = icon
        self.parentId = nil
        self.children = []
    }
    
//    func open() {
//        print("Open directory")
//    }
//    
//    func reveal() {
//        print("Reveal directory")
//    }
}

extension Directory: Entry {

//    var name: String {
//        return name
//    }
//    
//    var icon: Icon {
//        return icon
//    }
    
    func open() {
        print("打开目录（菜单中）")
    }
    
    func reveal() {
        print("不执行？")
    }
}
