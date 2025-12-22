//
//  Hashtag.swift
//  Stash
//
//  Created by Yan Meng on 2025/12/21.
//

struct Hashtag {
    let name: String
}

extension Hashtag: Identifiable {
    var id: String { name }
}
