//
//  Hashtag.swift
//  Stash
//
//  Created by Yan Meng on 2025/12/21.
//

import Foundation

struct Hashtag {
    let name: String
}

extension Hashtag: Identifiable {
    var id: UUID { UUID.deterministic(from: name) }
}

extension Hashtag: Collectible {
    var title: String { name }
    
    func relatedEntries(_ entries: [any Entry]) -> [any Entry] {
        entries.filter({ $0.name.contains(self.name) })
    }
}
