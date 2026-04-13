//
//  SyncModels.swift
//  Stash
//
//  Created by Cursor on 2026/4/13.
//

import Foundation

enum SyncMethod: String, CaseIterable, Codable, Identifiable {
    case local
    case icloud
    case baiduDisk
    case dropbox

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .local:
            return "Local Only"
        case .icloud:
            return "iCloud"
        case .baiduDisk:
            return "Baidu Disk"
        case .dropbox:
            return "Dropbox"
        }
    }
}

enum SyncRequestReason: String {
    case startup
    case localChange
    case providerSwitch
    case remoteChange
    case manual
    case becameActive
    case signedIn
}

enum SyncStatusLevel: Equatable {
    case idle
    case syncing
    case success
    case warning
    case error
}

enum SyncProviderAuthState: Equatable {
    case notRequired
    case signedOut
    case signedIn(String?)
    case needsConfiguration(String)
    case comingSoon(String)
}

struct SyncStatusSummary: Equatable {
    var level: SyncStatusLevel
    var title: String
    var detail: String?

    static let idleLocal = SyncStatusSummary(level: .idle, title: "Stored locally only", detail: nil)
}

struct SyncMetadata: Codable, Equatable {
    let schemaVersion: Int
    let deviceId: String
    let contentHash: String
    let revision: String
    let updatedAt: Date

    init(schemaVersion: Int = 1,
         deviceId: String,
         contentHash: String,
         revision: String,
         updatedAt: Date) {
        self.schemaVersion = schemaVersion
        self.deviceId = deviceId
        self.contentHash = contentHash
        self.revision = revision
        self.updatedAt = updatedAt
    }
}

struct SyncCheckpoint: Codable, Equatable {
    let method: SyncMethod
    let contentHash: String
    let revision: String?
    let updatedAt: Date
}

struct SyncRemoteSnapshot {
    let payloadData: Data
    let metadata: SyncMetadata
    let providerRevision: String?
}

struct SyncUploadResponse {
    let providerRevision: String?
    let metadata: SyncMetadata
}

struct SyncConflictState: Equatable {
    let method: SyncMethod
    let detectedAt: Date
    let localHash: String
    let remoteHash: String
    let remoteRevision: String?
}

enum SyncDecision: String, Equatable {
    case noop
    case upload
    case download
    case conflict
}

enum SyncConflictResolution {
    case keepLocal
    case useRemote
}

enum SyncPlanner {
    struct Input: Equatable {
        let localHash: String
        let localIsEmpty: Bool
        let remoteHash: String?
        let remoteRevision: String?
        let checkpoint: SyncCheckpoint?
    }

    static func decide(_ input: Input) -> SyncDecision {
        guard let remoteHash = input.remoteHash else {
            return .upload
        }

        if input.localHash == remoteHash {
            return .noop
        }

        guard let checkpoint = input.checkpoint else {
            return input.localIsEmpty ? .download : .conflict
        }

        let remoteUnchanged = checkpoint.contentHash == remoteHash ||
            (checkpoint.revision != nil && checkpoint.revision == input.remoteRevision)

        if remoteUnchanged {
            return input.localHash == checkpoint.contentHash ? .noop : .upload
        }

        if input.localHash == checkpoint.contentHash {
            return .download
        }

        return .conflict
    }
}
