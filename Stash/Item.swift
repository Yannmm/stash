//
//  Item.swift
//  Stash
//
//  Created by Yan Meng on 2025/1/28.
//

import Foundation
import SwiftData

// To be refactored.

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
