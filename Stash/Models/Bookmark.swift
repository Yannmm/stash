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
    var name: String
    var parentId: UUID?
    let url: URL
}

extension Bookmark: Entry {
    var icon: Icon {
        if url.isVnc {
          return .system("square.on.square.intersection.dashed")
        } else if url.isFileURL {
            return .local(url)
        } else {
            if let furl = url.faviconUrl {
                return .favicon(furl)
            } else {
                return .system("link")
            }
        }
    }
}

extension Bookmark: Actionable {
    func open() {
        NSWorkspace.shared.open(url)
    }
    
    func reveal() {
        guard revealable else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    
    var revealable: Bool { url.isFileURL }
}

