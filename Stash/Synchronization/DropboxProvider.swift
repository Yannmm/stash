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
        private let _incoming = PassthroughSubject<SidecarData, Never>()
        var incoming: AnyPublisher<SidecarData, Never> { _incoming.eraseToAnyPublisher() }

        init() {}

        func checkAvailability() async -> Availability {
            .no(ProviderError.notImplemented)
        }

        func readSidecar() async throws -> SidecarData {
            throw ProviderError.notImplemented
        }

        func readDocument() async throws -> Data {
            throw ProviderError.notImplemented
        }

        func send(document: Data, sidecar: SidecarData) async throws {
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

