//
//  DropboxProvider.swift
//  Stash
//
//  Created by Yan Meng on 2026/5/10.
//

import Foundation
import Combine

extension Synchronizer {
    final class DropboxProvider: Provider {
        private let _onArrive = PassthroughSubject<Sidecar, Never>()
        var onArrive: AnyPublisher<Sidecar, Never> { _onArrive.eraseToAnyPublisher() }

        init() {}

        func checkAvailability() async -> Availability {
            .no(ProviderError.notImplemented)
        }

        func sidecar() async throws -> Sidecar {
            throw ProviderError.notImplemented
        }

        func document() async throws -> Data {
            throw ProviderError.notImplemented
        }

        func send(document: Data, sidecar: Sidecar) async throws {
            throw ProviderError.notImplemented
        }
    }
}

extension Synchronizer.DropboxProvider {
    enum ProviderError: Error, LocalizedError {
        case notImplemented

        var errorDescription: String? {
            switch self {
            case .notImplemented:
                return "Dropbox sync is not yet implemented"
            }
        }
    }
}

