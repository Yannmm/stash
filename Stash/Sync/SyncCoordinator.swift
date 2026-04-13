//
//  SyncCoordinator.swift
//  Stash
//
//  Created by Cursor on 2026/4/13.
//

import Foundation
import Combine
import AppKit

final class SyncCoordinator: ObservableObject {
    @Published var selectedMethod: SyncMethod
    @Published private(set) var authState: SyncProviderAuthState
    @Published private(set) var status = SyncStatusSummary.idleLocal
    @Published private(set) var lastSyncAt: Date?
    @Published private(set) var conflict: SyncConflictState?
    @Published private(set) var isSyncing = false

    private let pieceSaver: PieceSaver
    private let store: StashPayloadStore
    private let localProvider: LocalSyncProvider
    private let iCloudProvider: ICloudSyncProvider
    private let baiduProvider: BaiduDiskSyncProvider
    private let dropboxProvider: DropboxSyncProvider
    private let deviceID: String

    private var providerObserver: AnyCancellable?
    private var pendingReasons = Set<SyncRequestReason>()
    private var pendingRemoteSnapshot: SyncRemoteSnapshot?
    private var remoteApplyHandler: (() -> Void)?
    private var backgroundScheduler: NSBackgroundActivityScheduler?

    init(pieceSaver: PieceSaver = PieceSaver(), store: StashPayloadStore = StashPayloadStore()) {
        self.pieceSaver = pieceSaver
        self.store = store
        self.localProvider = LocalSyncProvider()
        self.iCloudProvider = ICloudSyncProvider(store: store)
        self.baiduProvider = BaiduDiskSyncProvider(
            client: BaiduDiskClient(),
            pieceSaver: pieceSaver,
            keychain: KeychainStore(),
            store: store
        )
        self.dropboxProvider = DropboxSyncProvider()

        let legacyICloud: Bool = pieceSaver.value(for: .icloudSync) ?? true
        self.selectedMethod = pieceSaver.value(for: .syncMethod).flatMap(SyncMethod.init(rawValue:)) ?? (legacyICloud ? .icloud : .local)
        self.deviceID = pieceSaver.value(for: .appIdentifier) ?? UUID().uuidString
        self.authState = .notRequired
        self.lastSyncAt = pieceSaver.value(for: .syncLastDate)

        bindProviderObserver()
        refreshPublishedState()
    }

    var activeProvider: SyncProvider {
        provider(for: selectedMethod)
    }

    var baiduClientID: String { baiduProvider.clientID }
    var baiduRedirectURI: String { baiduProvider.redirectURI }
    var baiduRemoteDirectory: String { baiduProvider.remoteDirectory }

    func attachRemoteApplyHandler(_ handler: @escaping () -> Void) {
        self.remoteApplyHandler = handler
    }

    func setSelectedMethod(_ method: SyncMethod) {
        selectedMethod = method
        pieceSaver.save(for: .syncMethod, value: method.rawValue)
        pieceSaver.save(for: .icloudSync, value: method == .icloud)
        conflict = nil
        pendingRemoteSnapshot = nil
        bindProviderObserver()
        refreshPublishedState()
        requestSync(reason: .providerSwitch)
    }

    func requestSync(reason: SyncRequestReason) {
        pendingReasons.insert(reason)
        Task { @MainActor in
            await drainQueueIfNeeded()
        }
    }

    func startBackgroundRefresh() {
        guard backgroundScheduler == nil else { return }
        let scheduler = NSBackgroundActivityScheduler(identifier: "com.rayman.stash.sync.refresh")
        scheduler.interval = 15 * 60
        scheduler.tolerance = 5 * 60
        scheduler.repeats = true
        scheduler.schedule { [weak self] completion in
            guard let self else {
                completion(.finished)
                return
            }
            self.requestSync(reason: .manual)
            completion(.finished)
        }
        backgroundScheduler = scheduler
    }

    func handleDidBecomeActive() {
        requestSync(reason: .becameActive)
    }

    func disconnectSelectedProvider() {
        Task {
            do {
                try await activeProvider.signOut()
                conflict = nil
                pendingRemoteSnapshot = nil
                refreshPublishedState()
            } catch {
                publish(error: error)
            }
        }
    }

    func configureBaidu(clientID: String, clientSecret: String, redirectURI: String, remoteDirectory: String) throws {
        try baiduProvider.updateConfiguration(
            clientID: clientID,
            clientSecret: clientSecret,
            redirectURI: redirectURI,
            remoteDirectory: remoteDirectory
        )
        refreshPublishedState()
    }

    func startBaiduAuthorization() throws {
        let url = try baiduProvider.authorizationURL()
        NSWorkspace.shared.open(url)
        status = SyncStatusSummary(
            level: .idle,
            title: "Waiting for Baidu authorization",
            detail: "Approve the app in your browser. Nustash will continue automatically after Baidu redirects back."
        )
    }

    func handleOAuthCallback(_ url: URL) {
        Task {
            do {
                switch try await baiduProvider.handleOAuthRedirect(url) {
                case .ignored:
                    break
                case .handled:
                    refreshPublishedState()
                    status = SyncStatusSummary(
                        level: .success,
                        title: "Baidu sign-in completed",
                        detail: "Connected successfully. Sync will continue automatically."
                    )
                    requestSync(reason: .signedIn)
                }
            } catch {
                publish(error: error)
            }
        }
    }

    func resolveConflict(_ resolution: SyncConflictResolution) {
        Task {
            do {
                switch resolution {
                case .keepLocal:
                    let revision = pendingRemoteSnapshot?.providerRevision ?? pendingRemoteSnapshot?.metadata.revision
                    try await forceUploadCurrentPayload(expectedRevision: revision)
                case .useRemote:
                    try applyPendingRemoteSnapshot()
                }
                conflict = nil
                pendingRemoteSnapshot = nil
            } catch {
                publish(error: error)
            }
        }
    }

    private func refreshPublishedState() {
        authState = activeProvider.authState()
        if selectedMethod == .local {
            status = .idleLocal
        } else if case .comingSoon(let message) = authState {
            status = SyncStatusSummary(level: .warning, title: selectedMethod.displayName, detail: message)
        } else if case .needsConfiguration(let message) = authState {
            status = SyncStatusSummary(level: .warning, title: selectedMethod.displayName, detail: message)
        } else if case .signedOut = authState {
            status = SyncStatusSummary(level: .idle, title: "Sign in required", detail: "Connect \(selectedMethod.displayName) to enable sync.")
        }
    }

    private func bindProviderObserver() {
        providerObserver?.cancel()
        providerObserver = activeProvider.remoteChanges
            .sink { [weak self] in
                self?.requestSync(reason: .remoteChange)
            }
    }

    private func provider(for method: SyncMethod) -> SyncProvider {
        switch method {
        case .local:
            return localProvider
        case .icloud:
            return iCloudProvider
        case .baiduDisk:
            return baiduProvider
        case .dropbox:
            return dropboxProvider
        }
    }

    private func drainQueueIfNeeded() async {
        guard !isSyncing else { return }
        isSyncing = true

        while !pendingReasons.isEmpty {
            let reasons = pendingReasons
            pendingReasons.removeAll()
            await syncNow(reasons: reasons)
        }

        isSyncing = false
    }

    private func syncNow(reasons: Set<SyncRequestReason>) async {
        let provider = activeProvider
        authState = provider.authState()

        guard selectedMethod != .local else {
            status = .idleLocal
            return
        }

        if case .comingSoon(let message) = authState {
            status = SyncStatusSummary(level: .warning, title: selectedMethod.displayName, detail: message)
            return
        }

        if case .needsConfiguration(let message) = authState {
            status = SyncStatusSummary(level: .warning, title: selectedMethod.displayName, detail: message)
            return
        }

        if case .signedOut = authState {
            status = SyncStatusSummary(level: .idle, title: "Sign in required", detail: "Connect \(selectedMethod.displayName) to enable sync.")
            return
        }

        status = SyncStatusSummary(level: .syncing, title: "Syncing \(selectedMethod.displayName)", detail: reasons.map(\.rawValue).sorted().joined(separator: ", "))

        do {
            try await provider.prepare()
            let localURL = try store.localPayloadURL()
            try store.ensurePayloadExists(at: localURL)
            let localPayload = try store.readPayload(at: localURL)
            let localEntries = try store.deserializeEntries(from: localPayload)
            let localHash = store.contentHash(for: localPayload)
            let checkpoint = currentCheckpoint()
            let remote = try await provider.fetchRemoteSnapshot()

            let decision = SyncPlanner.decide(
                .init(
                    localHash: localHash,
                    localIsEmpty: localEntries.isEmpty,
                    remoteHash: remote?.metadata.contentHash,
                    remoteRevision: remote?.providerRevision ?? remote?.metadata.revision,
                    checkpoint: checkpoint
                )
            )

            switch decision {
            case .noop:
                if let remote {
                    persist(checkpoint: SyncCheckpoint(
                        method: selectedMethod,
                        contentHash: remote.metadata.contentHash,
                        revision: remote.providerRevision ?? remote.metadata.revision,
                        updatedAt: remote.metadata.updatedAt
                    ))
                }
                status = SyncStatusSummary(level: .success, title: "Up to date", detail: "Latest \(selectedMethod.displayName) data is already applied.")
            case .upload:
                try await forceUploadCurrentPayload(expectedRevision: checkpoint?.revision)
            case .download:
                guard let remote else { return }
                try applyRemoteSnapshot(remote)
            case .conflict:
                guard let remote else { return }
                pendingRemoteSnapshot = remote
                conflict = SyncConflictState(
                    method: selectedMethod,
                    detectedAt: Date(),
                    localHash: localHash,
                    remoteHash: remote.metadata.contentHash,
                    remoteRevision: remote.providerRevision ?? remote.metadata.revision
                )
                status = SyncStatusSummary(level: .warning, title: "Sync conflict detected", detail: "Choose whether to keep your local bookmarks or use the remote copy.")
            }
        } catch SyncProviderError.conflictDetected {
            if let remote = try? await provider.fetchRemoteSnapshot() {
                pendingRemoteSnapshot = remote
                conflict = SyncConflictState(
                    method: selectedMethod,
                    detectedAt: Date(),
                    localHash: "",
                    remoteHash: remote.metadata.contentHash,
                    remoteRevision: remote.providerRevision ?? remote.metadata.revision
                )
            }
            status = SyncStatusSummary(level: .warning, title: "Sync conflict detected", detail: "Remote data changed during upload. Review the conflict and retry.")
        } catch {
            publish(error: error)
        }
    }

    private func forceUploadCurrentPayload(expectedRevision: String?) async throws {
        let payload = try store.readPayload(at: store.localPayloadURL())
        let metadata = SyncMetadata(
            deviceId: deviceID,
            contentHash: store.contentHash(for: payload),
            revision: UUID().uuidString,
            updatedAt: Date()
        )

        let response = try await activeProvider.upload(
            payloadData: payload,
            metadata: metadata,
            previousRevision: expectedRevision
        )
        persist(checkpoint: SyncCheckpoint(
            method: selectedMethod,
            contentHash: response.metadata.contentHash,
            revision: response.providerRevision ?? response.metadata.revision,
            updatedAt: response.metadata.updatedAt
        ))
        status = SyncStatusSummary(level: .success, title: "Uploaded to \(selectedMethod.displayName)", detail: nil)
    }

    private func applyPendingRemoteSnapshot() throws {
        guard let snapshot = pendingRemoteSnapshot else { return }
        try applyRemoteSnapshot(snapshot)
    }

    private func applyRemoteSnapshot(_ snapshot: SyncRemoteSnapshot) throws {
        try store.writePayload(snapshot.payloadData, to: store.localPayloadURL())
        try? store.writeMetadata(snapshot.metadata, to: store.localMetadataURL())
        persist(checkpoint: SyncCheckpoint(
            method: selectedMethod,
            contentHash: snapshot.metadata.contentHash,
            revision: snapshot.providerRevision ?? snapshot.metadata.revision,
            updatedAt: snapshot.metadata.updatedAt
        ))
        remoteApplyHandler?()
        status = SyncStatusSummary(level: .success, title: "Downloaded latest from \(selectedMethod.displayName)", detail: nil)
    }

    private func currentCheckpoint() -> SyncCheckpoint? {
        guard let checkpoint = pieceSaver.codableValue(for: .syncCheckpoint, as: SyncCheckpoint.self),
              checkpoint.method == selectedMethod else {
            return nil
        }
        return checkpoint
    }

    private func persist(checkpoint: SyncCheckpoint) {
        do {
            try pieceSaver.saveCodable(checkpoint, for: .syncCheckpoint)
        } catch {
            ErrorTracker.shared.add(error)
        }
        lastSyncAt = checkpoint.updatedAt
        pieceSaver.save(for: .syncLastDate, value: checkpoint.updatedAt)
    }

    private func publish(error: Error) {
        ErrorTracker.shared.add(error)
        status = SyncStatusSummary(level: .error, title: "Sync failed", detail: error.localizedDescription)
    }
}
