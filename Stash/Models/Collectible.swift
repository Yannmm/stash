//
//  Collectible.swift
//  Stash
//
//  Created by Yan Meng on 2026/1/11.
//

// A collection can be a group or hashtag
protocol Collectible {
    var title: String { get }
    
    func relatedEntries(_ entries: [any Entry]) -> [any Entry]
}
