//
//  Icon.swift
//  Stash
//
//  Created by Rayman on 2025/3/28.
//

import Foundation

enum Icon: Codable {
    case favicon(URL)
    case system(String)
    case local(URL)
}

extension Icon: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (let .favicon(a), let .favicon(b)):
            return a == b
        case (let .system(a), let .system(b)):
            return  a == b
        case (let .local(a), let .local(b)):
            return a == b
        default:
            return false
        }
    }
}
