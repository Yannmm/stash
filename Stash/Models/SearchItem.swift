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
    
    static func == (lhs: SearchItem, rhs: SearchItem) -> Bool {
        lhs.id == rhs.id
    }
}

extension SearchItem {
    static func back(title: String, detail: String) -> SearchItem {
        SearchItem(id: UUID(), title: title, detail: detail, icon: .system("arrowshape.turn.up.backward.fill"))
    }
}
