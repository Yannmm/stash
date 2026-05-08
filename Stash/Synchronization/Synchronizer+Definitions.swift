//
//  SyncModels.swift
//  Stash
//
//  Created by Cursor on 2026/4/13.
//

import Foundation

extension Synchronizer {
    enum Method: String, CaseIterable, Codable, Identifiable {
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
    
    enum Timing: String {
        case startup
        case localChange
        case providerSwitch
        case remoteChange
        case manual
        case becameActive
        case signedIn
    }
    
    enum Status: Equatable {
        case idle
        case syncing
        case success
        case warning
        case error
    }
    
    enum AuthState: Equatable {
        case notRequired
        case signedOut
        case signedIn(String?)
        case needsConfiguration(String)
        case comingSoon(String)
    }
    
    struct SyncStatusSummary: Equatable {
        var level: Status
        var title: String
        var detail: String?
        
        static let idleLocal = SyncStatusSummary(level: .idle, title: "Stored locally only", detail: nil)
    }
    
    struct Metadata: Codable, Equatable {
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
    
    struct Checkpoint: Codable, Equatable {
        let method: Method
        let contentHash: String
        let revision: String?
        let updatedAt: Date
    }
    
    struct RemoteSnapshot {
        let payloadData: Data
        let metadata: Metadata
        let providerRevision: String?
    }
    
    struct UploadResponse {
        let providerRevision: String?
        let metadata: Metadata
    }
    
    struct ConflictState: Equatable {
        let method: Method
        let detectedAt: Date
        let localHash: String
        let remoteHash: String
        let remoteRevision: String?
    }
    
    enum Decision: String, Equatable {
        case noop
        case upload
        case download
        case conflict
    }
    
    enum ConflictResolution {
        case keepLocal
        case useRemote
    }
    
    enum Planner {
        struct Input: Equatable {
            let localHash: String
            let localIsEmpty: Bool
            let remoteHash: String?
            let remoteRevision: String?
            let checkpoint: Checkpoint?
        }
        
        static func decide(_ input: Input) -> Decision {
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
    
}
