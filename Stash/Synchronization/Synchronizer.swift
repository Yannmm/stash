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
        static func initialize() async throws -> Self
        
        var onFileChange: AnyPublisher<Result<URL, Error>, Never> { get }
        
        func save(document html: String) async throws
        
        func load() throws -> String
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
    
    enum FileName {
        static let document = "default.html"
        static let sidecar = "default.html.sidecar"
    }
}
