//
//  Relic.swift
//  Stash
//
//  Created by Rayman on 2025/2/10.
//

import Cocoa

struct Bookmark {
    var id: UUID
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
                return .system("globe")
            }
        }
    }
    
    var container: Bool { false }
    
    var shouldExpand: Bool { true }
    
    var height: CGFloat { CellView.Constant.bookmarkHeight }
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

