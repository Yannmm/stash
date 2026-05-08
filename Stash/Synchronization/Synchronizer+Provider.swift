//
//  SyncProvider.swift
//  Stash
//
//  Created by Cursor on 2026/4/13.
//

import Foundation
import Combine

extension Synchronizer {
    protocol SyncProvider: AnyObject {
        var method: Method { get }
        var displayName: String { get }
        var remoteChanges: AnyPublisher<Void, Never> { get }

        func authState() -> AuthState
        func prepare() async throws
        func fetchRemoteSnapshot() async throws -> RemoteSnapshot?
        func upload(payloadData: Data, metadata: Metadata, previousRevision: String?) async throws -> UploadResponse
        func signOut() async throws
    }
}

extension Synchronizer.SyncProvider {
    var remoteChanges: AnyPublisher<Void, Never> {
        Empty(completeImmediately: false).eraseToAnyPublisher()
    }

    func signOut() async throws {}
}

extension Synchronizer {
    enum SyncProviderError: LocalizedError {
        case notAuthenticated(String)
        case needsConfiguration(String)
        case notImplemented(String)
        case conflictDetected

        var errorDescription: String? {
            switch self {
            case .notAuthenticated(let provider):
                return "\(provider) is not signed in."
            case .needsConfiguration(let message):
                return message
            case .notImplemented(let message):
                return message
            case .conflictDetected:
                return "Sync conflict detected. Review local and remote changes before continuing."
            }
        }
    }
}

extension Synchronizer {
    final class LocalSyncProvider: SyncProvider {
        let method: Method = .local
        let displayName = Method.local.displayName

        func authState() -> AuthState {
            .notRequired
        }

        func prepare() async throws {}

        func fetchRemoteSnapshot() async throws -> RemoteSnapshot? {
            nil
        }

        func upload(payloadData: Data, metadata: Metadata, previousRevision: String?) async throws -> UploadResponse {
            UploadResponse(providerRevision: metadata.revision, metadata: metadata)
        }
    }

    final class DropboxSyncProvider: SyncProvider {
        let method: Method = .dropbox
        let displayName = Method.dropbox.displayName

        func authState() -> AuthState {
            .comingSoon("Dropbox support is scaffolded but not implemented yet.")
        }

        func prepare() async throws {}

        func fetchRemoteSnapshot() async throws -> RemoteSnapshot? {
            nil
        }

        func upload(payloadData: Data, metadata: Metadata, previousRevision: String?) async throws -> UploadResponse {
            throw SyncProviderError.notImplemented("Dropbox support is not implemented yet.")
        }
    }
}
