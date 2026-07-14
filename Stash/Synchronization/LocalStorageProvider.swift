import Foundation
import Combine

extension Synchronizer {
    final class LocalStorageProvider: Provider {
        private let _onArrive = PassthroughSubject<Sidecar, Never>()
        var onArrive: AnyPublisher<Sidecar, Never> { _onArrive.eraseToAnyPublisher() }
        
        var availability: AnyPublisher<Availability, Never> { _availability.eraseToAnyPublisher() }
        private let _availability = CurrentValueSubject<Availability, Never>(.yes)

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

        func sidecar() async throws -> Sidecar {
            try _sidecar()
        }

        func document() async throws -> Data {
            try _document()
        }

        func send(document: Data, sidecar: Sidecar) async throws {
            let localSidecar = try? _sidecar()
            if let localSidecar, localSidecar.uid == sidecar.uid {
                return
            }
            try document.write(to: documentURL, options: .atomic)
            let sidecarData = try JSONEncoder().encode(sidecar)
            try sidecarData.write(to: sidecarURL, options: .atomic)
            _onArrive.send(sidecar)
        }

        func checkAvailability() async -> Availability {
            let a: Availability = .yes
            defer { _availability.send(a) }
            return .yes
        }

        // MARK: - Non-protocol (local hub role)
        @discardableResult
        func write(html: String) throws -> Sidecar {
            let sidecar = Sidecar.stamp()
            guard let document = html.data(using: .utf8) else {
                throw SyncError.corruptDocument
            }
            try document.write(to: documentURL, options: .atomic)
            let sidecarData = try JSONEncoder().encode(sidecar)
            try sidecarData.write(to: sidecarURL, options: .atomic)
            return sidecar
        }
        
        private func _sidecar() throws -> Sidecar {
            let data = try Data(contentsOf: sidecarURL)
            return try JSONDecoder().decode(Sidecar.self, from: data)
        }
        
        private func _document() throws -> Data {
            try Data(contentsOf: documentURL)
        }
    }
}
