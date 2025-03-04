//
//  Combo.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/11.
//

import Foundation

struct Directory: Codable {
    let id: UUID
    let name: String
    var parentId: UUID?
    
    var children: [any Entry]?
    
    enum CodingKeys: CodingKey {
        case id
        case name
        case parentId
    }
}

extension Directory: Entry {
    var icon: Icon {
        return .system("folder")
    }
    
    func open() {
        print("打开目录（菜单中）")
    }
    
    func reveal() {
        print("不执行？")
    }
}
