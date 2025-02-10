//
//  Bookmark.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/9.
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
