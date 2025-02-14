//
//  Task.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/14.
//

import SwiftUI

struct Task: Identifiable, Hashable {
    var id: UUID = .init()
    var title: String
    var status: Status
}

enum Status {
    case todo
    case working
    case completed
}
