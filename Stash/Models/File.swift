//
//  File.swift
//  Stash
//
//  Created by Yan Meng on 2025/3/23.
//

import Foundation

struct File {
    let id: UUID
    var name: String
    var parentId: UUID?
    var children: [any Entry]?
}

//extension Directory: Entry {
//    var icon: Icon {
//        return .system("square.stack.3d.down.right.fill")
//    }
//    
//    func open() {
//        print("打开目录（菜单中）")
//    }
//    
//    func reveal() {
//        print("不执行？")
//    }
//}
