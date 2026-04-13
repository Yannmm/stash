//
//  SyncProvider.swift
//  Stash
//
//  Created by Cursor on 2026/4/13.
//

import Foundation
import Combine

protocol SyncProvider: AnyObject {
    var method: SyncMethod { get }
    var displayName: String { get }
    var remoteChanges: AnyPublisher<Void, Never> { get }

    func authState() -> SyncProviderAuthState
    func prepare() async throws
    func fetchRemoteSnapshot() async throws -> SyncRemoteSnapshot?
    func upload(payloadData: Data, metadata: SyncMetadata, previousRevision: String?) async throws -> SyncUploadResponse
    func signOut() async throws
}

extension SyncProvider {
    var remoteChanges: AnyPublisher<Void, Never> {
        Empty(completeImmediately: false).eraseToAnyPublisher()
    }

    func signOut() async throws {}
}

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

final class LocalSyncProvider: SyncProvider {
    let method: SyncMethod = .local
    let displayName = SyncMethod.local.displayName

    func authState() -> SyncProviderAuthState {
        .notRequired
    }

    func prepare() async throws {}

    func fetchRemoteSnapshot() async throws -> SyncRemoteSnapshot? {
        nil
    }

    func upload(payloadData: Data, metadata: SyncMetadata, previousRevision: String?) async throws -> SyncUploadResponse {
        SyncUploadResponse(providerRevision: metadata.revision, metadata: metadata)
    }
}

final class DropboxSyncProvider: SyncProvider {
    let method: SyncMethod = .dropbox
    let displayName = SyncMethod.dropbox.displayName

    func authState() -> SyncProviderAuthState {
        .comingSoon("Dropbox support is scaffolded but not implemented yet.")
    }

    func prepare() async throws {}

    func fetchRemoteSnapshot() async throws -> SyncRemoteSnapshot? {
        nil
    }

    func upload(payloadData: Data, metadata: SyncMetadata, previousRevision: String?) async throws -> SyncUploadResponse {
        throw SyncProviderError.notImplemented("Dropbox support is not implemented yet.")
    }
}
