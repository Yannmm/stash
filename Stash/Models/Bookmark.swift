//
//  Relic.swift
//  Stash
//
//  Created by Rayman on 2025/2/10.
//

import Cocoa

// TODO: To support
// 1. Open Web url with browser
// 2. Open Local file url (or run local script) with default application or Show in finder
// 3. App Url Scheme

class Bookmark: Identifiable {
    let id: UUID
    let title: String
    let url: URL
    weak var parent: (any Entry)?
    
    init(id: UUID, title: String, url: URL, parent: (any Entry)? = nil) {
        self.id = id
        self.title = title
        self.url = url
        self.parent = parent
    }
}

extension Bookmark: Entry {
    var children: [any Entry]? {
        get {
            return nil
        }
        set {}
    }
    
    var name: String {
        return title
    }
    
    var icon: Icon {
        return Icon.favicon(url.faviconUrl)
    }
    
    func open() {
        NSWorkspace.shared.open(url)
    }
    
    func reveal() {
        print("finder 中打开文件所在位置111")
    }
    
}

