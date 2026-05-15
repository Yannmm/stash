//
//  Synchronizer.swift
//  Stash
//
//  Created by Rayman on 2026/5/11.
//

import Foundation
import Combine

class Synchronizer {
    
}

extension Synchronizer {
    protocol Provider {
        func monitor(_ start: Bool)
        
        static func initialize() async throws -> Self
        
        var onFileChange: AnyPublisher<Result<URL, Error>, Never> { get }
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
    
    enum Constant {
        static let contentFileName = "default.html"
        static let sidecarFileName = "default.html.sidecar"
    }
}
