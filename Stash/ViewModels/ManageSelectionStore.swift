//
//  ManageSelectionStore.swift
//  Stash
//
//  Created by Rayman on 2026/1/30.
//

import Foundation

class ManageSelectionStore: ObservableObject {
    let cabinet: OkamuraCabinet
    @Published var collection: (any Collectible)?
    
    init(cabinet: OkamuraCabinet) {
        self.cabinet = cabinet
    }
}
