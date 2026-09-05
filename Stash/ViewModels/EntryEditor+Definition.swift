//
//  EntryEditor+Definition.swift
//  Stash
//
//  Created by Rayman on 2026/3/19.
//

import Foundation

enum EntryEditor {
    enum Mode {
        case create(UUID?) // associated type - parent id if exists
        case update(UUID) // associated type - entry id
    }
    
    enum Field: Hashable {
        case path
        case title
        case hashtag
    }
    
    enum CraftError: Error {
        case emptyPath
        case invalidUrl(String)
        case unsupportedUrl(String)
        case entryNotFound(UUID)
    }
}



