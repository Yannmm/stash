//
//  Bookmark.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/9.
//

import Foundation

struct Bookmark: Identifiable, Codable {
    let id: UUID
    let title: String
    let url: URL
}
