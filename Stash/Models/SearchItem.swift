//
//  SearchItem.swift
//  Stash
//
//  Created by Yan Meng on 2025/7/28.
//

import Foundation

struct SearchItem: Identifiable, Equatable {
    let id: UUID
    let title: String
    let detail: String
    let icon: Icon
    let type: EntryType
    
    static func == (lhs: SearchItem, rhs: SearchItem) -> Bool {
        lhs.id == rhs.id
    }
}
