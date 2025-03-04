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

struct Bookmark: Codable {
    let id: UUID
    let name: String
    var parentId: UUID?
    let url: URL
    
//    init(id: UUID, name: String, url: URL) {
//        self.id = id
//        self.name = name
//        self.url = url
//        self.parentId = nil
//    }
}

extension Bookmark: Entry {
    var icon: Icon {
        return .favicon(url.faviconUrl)
    }
    
    var children: [any Entry]? {
        get { nil }
        set {}
    }
    
    func open() {
        NSWorkspace.shared.open(url)
    }
    
    func reveal() {
        print("Reveal bookmark")
    }
    
}

