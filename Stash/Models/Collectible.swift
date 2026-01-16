//
//  Collectible.swift
//  Stash
//
//  Created by Yan Meng on 2026/1/11.
//

import Foundation

// A collection can be a group or hashtag
protocol Collectible {
    var title: String { get }
    var id: UUID { get }
    
    func relatedEntries(_ entries: [any Entry]) -> [any Entry]
}
