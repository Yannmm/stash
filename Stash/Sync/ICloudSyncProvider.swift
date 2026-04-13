//
//  ICloudSyncProvider.swift
//  Stash
//
//  Created by Cursor on 2026/4/13.
//

import Foundation
import Combine

final class ICloudSyncProvider: SyncProvider {
    let method: SyncMethod = .icloud
    let displayName = SyncMethod.icloud.displayName

    private let store: StashPayloadStore
    private lazy var monitor = IcloudFileMonitor(filename: StashPayloadStore.Constant.metadataFileName)

    init(store: StashPayloadStore) {
        self.store = store
    }

    var remoteChanges: AnyPublisher<Void, Never> {
        monitor.$onChange
            .compactMap { $0 }
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    func authState() -> SyncProviderAuthState {
        do {
            _ = try store.iCloudDirectoryURL()
            return .signedIn("Available on this Mac")
        } catch {
            return .needsConfiguration("iCloud Drive is unavailable for this app on this Mac.")
        }
    }

    func prepare() async throws {
        _ = try store.iCloudDirectoryURL()
    }

    func fetchRemoteSnapshot() async throws -> SyncRemoteSnapshot? {
        let payloadURL = try store.iCloudPayloadURL()
        let metadataURL = try store.iCloudMetadataURL()
        guard FileManager.default.fileExists(atPath: payloadURL.path) else {
            return nil
        }

        let payload = try store.readPayload(at: payloadURL)
        let metadata = try store.normalizedMetadata(at: metadataURL, payloadData: payload) ??
            SyncMetadata(
                deviceId: "icloud",
                contentHash: store.contentHash(for: payload),
                revision: UUID().uuidString,
                updatedAt: Date()
            )

        return SyncRemoteSnapshot(
            payloadData: payload,
            metadata: metadata,
            providerRevision: metadata.revision
        )
    }

    func upload(payloadData: Data, metadata: SyncMetadata, previousRevision: String?) async throws -> SyncUploadResponse {
        if let existing = try await fetchRemoteSnapshot(),
           let previousRevision,
           existing.metadata.revision != previousRevision,
           existing.metadata.contentHash != metadata.contentHash {
            throw SyncProviderError.conflictDetected
        }

        try store.writePayload(payloadData, to: try store.iCloudPayloadURL())
        try store.writeMetadata(metadata, to: try store.iCloudMetadataURL())
        return SyncUploadResponse(providerRevision: metadata.revision, metadata: metadata)
    }
}
