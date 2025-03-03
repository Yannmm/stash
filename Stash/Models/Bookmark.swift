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

struct Bookmark {
    let id: UUID
    let name: String
    var parentId: UUID?
    let url: URL
    let icon: Icon
    var children: [any Entry]?
    
    init(id: UUID, name: String, url: URL, icon: Icon = .system("link")) {
        self.id = id
        self.name = name
        self.url = url
        self.icon = icon
        self.parentId = nil
        self.children = nil
    }
    
//    func open() {
//        NSWorkspace.shared.open(url)
//    }
//    
//    func reveal() {
//        print("Reveal bookmark")
//    }
}

extension Bookmark: Entry {
//    var children: [any Entry]? {
//        get { nil }
//        set {}
//    }
    

    
    func open() {
        NSWorkspace.shared.open(url)
    }
    
    func reveal() {
        print("Reveal bookmark")
    }
    
}

