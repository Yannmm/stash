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
