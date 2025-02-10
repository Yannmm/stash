//
//  Relic.swift
//  Stash
//
//  Created by Rayman on 2025/2/10.
//

import Foundation

struct Relic: Identifiable, Codable {
    let id: UUID
    let title: String
    let url: URL
}

extension Relic: Dish {
    var name: String {
        return title
    }
}
