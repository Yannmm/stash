//
//  Provider.swift
//  Stash
//
//  Created by Yan Meng on 2026/8/22.
//

import Combine
import Foundation

// MARK: - Provider

extension Synchronizer {
    protocol Provider {
        var onArrive: AnyPublisher<Sidecar, Never> { get }
        
        func sidecar() async throws -> Sidecar
        
        func document() async throws -> Data
        
        func prepare() async throws
        
        func pause() async throws
    }
    
    protocol RemoteProvider: Provider {
        func send(document: Data, sidecar: Sidecar) async throws
        
        var readiness: AnyPublisher<Result<any ProviderReadiness, Error>, Never> { get }
        
        var strayError: AnyPublisher<(String, Error)?, Never> { get }
    }
    
    protocol LocalProvider: Provider {
        
        func copy(document: Data, sidecar: Sidecar) async throws
        
        @discardableResult
        func write(html: String) throws -> Sidecar
    }
}

extension Synchronizer.Provider {
    func prepare() async throws {}
    
    func pause() async throws {}
}
