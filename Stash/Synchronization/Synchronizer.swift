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
        
        func initialize() async throws
        
        // For icloud, check availability, for others, check whether signed-in
        func available() async -> Availability
    }
    
    struct Paths {
        let document: URL
        let sidecar: URL
    }
    
    enum Approach {
        case icloud
        case local
        case dropbox
    }
    
    enum Availability {
        case notSupport
        case notSignedInYet
        case ready
    }
}
