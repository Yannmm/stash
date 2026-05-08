//
//  StashPayloadStore.swift
//  Stash
//
//  Created by Cursor on 2026/4/13.
//

import Foundation
import CryptoKit

extension Synchronizer {
    struct StashPayloadStore {
        enum Constant {
            static let containerDirectoryName = "Stash"
            static let dataFileName = "default.html"
            static let metadataFileName = "default.html.sidecar"
        }

        private let fileManager = FileManager.default

        func serialize(entries: [any Entry]) throws -> Data {
            let data = try JSONEncoder().encode(entries.asAnyEntries)
            let json = try JSONSerialization.jsonObject(with: data)
            let dominator = Dominator()
            let html = try dominator.compose(json)
            guard let result = html.data(using: .utf8) else {
                throw PayloadStoreError.invalidEncoding
            }
            return result
        }

        func deserializeEntries(from data: Data) throws -> [any Entry] {
            guard let html = String(data: data, encoding: .utf8) else {
                throw PayloadStoreError.invalidEncoding
            }
            let dominator = Dominator()
            let jsonData = try dominator.decompose(html)
            let entries = try JSONDecoder().decode([AnyEntry].self, from: jsonData)
            return entries.asEntries
        }

        func readPayload(at url: URL) throws -> Data {
            try Data(contentsOf: url)
        }

        func readEntries(at url: URL) throws -> [any Entry] {
            try deserializeEntries(from: readPayload(at: url))
        }

        func writePayload(_ data: Data, to url: URL) throws {
            try ensureParentDirectoryExists(for: url)
            try data.write(to: url, options: .atomic)
        }

        @discardableResult
        func ensurePayloadExists(at url: URL, entries: [any Entry] = []) throws -> Bool {
            guard !fileManager.fileExists(atPath: url.path) else { return false }
            try writePayload(serialize(entries: entries), to: url)
            return true
        }

        func serialize(metadata: Metadata) throws -> Data {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.sortedKeys]
            return try encoder.encode(metadata)
        }

        func deserializeMetadata(from data: Data) throws -> Metadata {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(Metadata.self, from: data)
        }

        func readMetadata(at url: URL) throws -> Data {
            try Data(contentsOf: url)
        }

        func writeMetadata(_ metadata: Metadata, to url: URL) throws {
            try ensureParentDirectoryExists(for: url)
            try serialize(metadata: metadata).write(to: url, options: .atomic)
        }

        func normalizedMetadata(at url: URL, payloadData: Data) throws -> Metadata? {
            guard fileManager.fileExists(atPath: url.path) else { return nil }
            let data = try readMetadata(at: url)
            if let metadata = try? deserializeMetadata(from: data) {
                return metadata
            }

            guard let legacyRevision = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
                  !legacyRevision.isEmpty else {
                return nil
            }

            return Metadata(
                deviceId: legacyRevision,
                contentHash: contentHash(for: payloadData),
                revision: legacyRevision,
                updatedAt: Date()
            )
        }

        func contentHash(for data: Data) -> String {
            let digest = SHA256.hash(data: data)
            return digest.map { String(format: "%02x", $0) }.joined()
        }

        func localDirectoryURL() throws -> URL {
            guard let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
                throw PayloadStoreError.missingApplicationSupportDirectory
            }
            let directory = support.appendingPathComponent(Constant.containerDirectoryName, isDirectory: true)
            if !fileManager.fileExists(atPath: directory.path) {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            }
            return directory
        }

        func localPayloadURL() throws -> URL {
            try localDirectoryURL().appendingPathComponent(Constant.dataFileName)
        }

        func localMetadataURL() throws -> URL {
            try localDirectoryURL().appendingPathComponent(Constant.metadataFileName)
        }

        func iCloudDirectoryURL() throws -> URL {
            guard let container = fileManager.url(forUbiquityContainerIdentifier: nil) else {
                throw PayloadStoreError.icloudContainerUnavailable
            }

            let directory = container.appendingPathComponent("Documents", isDirectory: true)
            if !fileManager.fileExists(atPath: directory.path) {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            }
            return directory
        }

        func iCloudPayloadURL() throws -> URL {
            try iCloudDirectoryURL().appendingPathComponent(Constant.dataFileName)
        }

        func iCloudMetadataURL() throws -> URL {
            try iCloudDirectoryURL().appendingPathComponent(Constant.metadataFileName)
        }

        private func ensureParentDirectoryExists(for url: URL) throws {
            let parent = url.deletingLastPathComponent()
            if !fileManager.fileExists(atPath: parent.path) {
                try fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
            }
        }
    }
}

extension Synchronizer.StashPayloadStore {
    enum PayloadStoreError: Error {
        case invalidEncoding
        case missingApplicationSupportDirectory
        case icloudContainerUnavailable
    }
}
