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
        
        func sidecar() async throws -> Sidecar // TODO: remove throws
        
        func document() async throws -> Data // TODO: remove throws
        
        func send(document: Data, sidecar: Sidecar) async throws
        
        var availability: AnyPublisher<Availability, Never> { get }
        
        func getAvailability() async -> Availability
        
        func prepare() async throws
        
        func pause() async throws
    }
}

extension Synchronizer.Provider {
    func getAvailability() async -> Synchronizer.Availability {
        let a = await availability.values.first(where: { _ in true })
        return a!
    }
    
    func prepare() async throws {}
    
    func pause() async throws {}
}

// MARK: - Availability

extension Synchronizer {
    enum Availability: Equatable, Synchronizer.Descriptor {
        static func == (lhs: Availability, rhs: Availability) -> Bool {
            switch (lhs, rhs) {
            case (.yes, .yes): return true
            case (.no, .no): return true
            default: return false
            }
        }
        case yes(Synchronizer.Descriptor)
        case no(Synchronizer.Descriptor)
    }
}

extension Synchronizer.Availability {
    func describe() -> AttributedString {
        switch self {
        case .yes(let descriptor):
            return descriptor.describe()
        case .no(let descriptor):
            return descriptor.describe()
        }
    }
    
    func action(_ phrase: String) {
        switch self {
        case .yes(let descriptor):
            descriptor.action(phrase)
        case .no(let descriptor):
            descriptor.action(phrase)
        }
    }
}
