//
//  CellViewModel.swift
//  Stash
//
//  Created by Rayman on 2025/5/21.
//

import Combine

class CellViewModel: ObservableObject {
    @Published var entry: (any Entry)?
    
    var cabinet: OkamuraCabinet!
    
    @Published var title: String
    
    init(entry: (any Entry)? = nil) {
        self.entry = entry
        self.title = entry?.name ?? ""
    }
    
    func update() throws {
        guard var e = entry else { return }
        guard e.name != title else { return }
        guard !title.trim().isEmpty else {
            title = e.name
            return
        }
        e.name = title
        try cabinet.update(entry: e)
    }
}
