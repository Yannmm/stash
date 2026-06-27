import Foundation
import Combine

extension Synchronizer {
    final class LocalStorageProvider: Provider {
        private let _incoming = PassthroughSubject<SidecarData, Never>()
        var incoming: AnyPublisher<SidecarData, Never> { _incoming.eraseToAnyPublisher() }

        private let directory: URL

        init() {
            let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            directory = support.appendingPathComponent("Stash", isDirectory: true)
            if !FileManager.default.fileExists(atPath: directory.path) {
                try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            }
        }

        private var documentURL: URL {
            directory.appendingPathComponent(FileName.document)
        }

        private var sidecarURL: URL {
            directory.appendingPathComponent(FileName.sidecar)
        }

        // MARK: - Protocol conformance

        func readSidecar() async throws -> SidecarData {
            try readSidecarSync()
        }

        func readDocument() async throws -> Data {
            try readDocumentSync()
        }

        func send(document: Data, sidecar: SidecarData) throws {
            let localSidecar = try? readSidecarSync()
            if let localSidecar, localSidecar.uid == sidecar.uid {
                return
            }
            try document.write(to: documentURL, options: .atomic)
            let sidecarData = try JSONEncoder().encode(sidecar)
            try sidecarData.write(to: sidecarURL, options: .atomic)
            _incoming.send(sidecar)
        }

        func checkAvailability() async -> Availability {
            .yes
        }

        // MARK: - Non-protocol (local hub role)

        @discardableResult
        func write(html: String) throws -> SidecarData {
            let sidecar = SidecarData.stamp()
            guard let documentData = html.data(using: .utf8) else {
                throw SyncError.corruptDocument
            }
            try documentData.write(to: documentURL, options: .atomic)
            let sidecarData = try JSONEncoder().encode(sidecar)
            try sidecarData.write(to: sidecarURL, options: .atomic)
            return sidecar
        }

        func readSidecarSync() throws -> SidecarData {
            let data = try Data(contentsOf: sidecarURL)
            return try JSONDecoder().decode(SidecarData.self, from: data)
        }

        func readDocumentSync() throws -> Data {
            try Data(contentsOf: documentURL)
        }
    }
}
