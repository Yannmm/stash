//
//  Synchronizer.swift
//  Stash
//
//  Created by Rayman on 2026/5/11.
//

import Foundation

class Synchronizer {
    
}

extension Synchronizer {
    protocol Provider {
        func getPaths() throws -> Paths
        
        func monitor(_ start: Bool)
        
        func prepare()
    }
    
    struct Paths {
        let document: URL
        let sidecar: URL
    }
}
