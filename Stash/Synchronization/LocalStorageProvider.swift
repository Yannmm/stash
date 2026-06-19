//
//  LocalStorageProvider.swift
//  Stash
//
//  Created by Yan Meng on 2026/6/18.
//

import Combine
import Foundation

extension Synchronizer {
    final class LocalStorageProvider: Provider {
        
        init() {}
        
        private let _onRemoteChange = PassthroughSubject<Result<URL, Error>, Never>()
        
        var onRemoteChange: AnyPublisher<Result<URL, Error>, Never> { _onRemoteChange.eraseToAnyPublisher() }
        
        private let _available = PassthroughSubject<Availability, Never>()
        
        var available: AnyPublisher<Synchronizer.Availability, Never> { _available.eraseToAnyPublisher() }
        
        func synchronize(source: Synchronizer.Paths) async throws {
            
        }
        
        func prepare() async throws {
            
        }
        
        func pause() async throws {
            
        }
        
        
    }
}
