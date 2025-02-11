//
//  Relic.swift
//  Stash
//
//  Created by Rayman on 2025/2/10.
//

import Foundation

// TODO: To support
// 1. Open Web url with browser
// 2. Open Local file url (or run local script) with default application or Show in finder
// 3. App Url Scheme

struct Bookmark: Identifiable, Codable {
    let id: UUID
    let title: String
    let url: URL
}

extension Bookmark: Entry {
    var name: String {
        return title
    }
    
    func open() {
        print("打开文件 / 执行脚本")
    }
    
    func reveal() {
        print("finder 中打开文件所在位置")
    }
    
}
