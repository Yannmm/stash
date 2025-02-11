//
//  Combo.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/11.
//

import Foundation

struct Directory {
    let title: String
    let entries: [Entry]
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
