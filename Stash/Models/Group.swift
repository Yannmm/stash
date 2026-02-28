//
//  Combo.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/11.
//

import Foundation
import OrderedCollections

/// Logical group
struct Group {
    var id: UUID
    var name: String
    var parentId: UUID?
    var hashtags: OrderedSet<String>?
}

extension Group: Entry {
    var icon: Icon { .system("cube.box.fill") }
    
    var container: Bool { true }
}

extension Group {
    var unboxable: Bool { container }
}

extension Group: Collectible {
    var title: String { name }
    
    func relatedEntries(_ entries: [any Entry]) -> [any Entry] {
        self.children(among: entries)
    }
}
