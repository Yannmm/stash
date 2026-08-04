import Foundation
import Combine

extension Synchronizer {
    final class OnPremiseProvider: Provider {
        private let _onArrive = PassthroughSubject<Sidecar, Never>()
        var onArrive: AnyPublisher<Sidecar, Never> { _onArrive.eraseToAnyPublisher() }
        
        var availability: AnyPublisher<Availability, Never> { _availability.eraseToAnyPublisher() }
        private let _availability = CurrentValueSubject<Availability, Never>(.yes("Local"))
        
        private let directory: URL
        
        init() {
            let fmgr = FileManager.default
            let support = fmgr.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            directory = support.appendingPathComponent("Stash", isDirectory: true)
            do {
                if !fmgr.fileExists(atPath: directory.path) {
                    try fmgr.createDirectory(at: directory, withIntermediateDirectories: true)
                }
                
                if !fmgr.fileExists(atPath: sidecarURL.path) {
                    let kk = Sidecar.stamp()
                    let encoder = JSONEncoder()
                    // Optional: Make the JSON human-readable
                    encoder.outputFormatting = .prettyPrinted
                    
                    let data = try encoder.encode(kk)
                    let success = fmgr.createFile(atPath: sidecarURL.path, contents: data, attributes: nil)
                }
                if !fmgr.fileExists(atPath: documentURL.path) {
                    let success = fmgr.createFile(atPath: documentURL.path, contents: Data(), attributes: nil)
                }
            } catch {
                ErrorTracker.shared.add(error)
            }
        }
        
        private var documentURL: URL {
            directory.appendingPathComponent(FileName.document)
        }
        
        private var sidecarURL: URL {
            directory.appendingPathComponent(FileName.sidecar)
        }
        
        // MARK: - Protocol conformance
        
        func sidecar() async throws -> Sidecar? {
            _sidecar()
        }
        
        func document() async throws -> Data? {
            try _document()
        }
        
        func send(document: Data, sidecar: Sidecar) async throws {
            let localSidecar = _sidecar()
            if let localSidecar, localSidecar.uid == sidecar.uid {
                return
            }
            try document.write(to: documentURL, options: .atomic)
            let sidecarData = try JSONEncoder().encode(sidecar)
            try sidecarData.write(to: sidecarURL, options: .atomic)
            _onArrive.send(sidecar)
        }
        
        func checkAvailability() async -> Availability {
            let a: Availability = .yes("Local")
            defer { _availability.send(a) }
            return a
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
        
        private func _sidecar() -> Sidecar? {
            do {
                let data = try Data(contentsOf: sidecarURL)
                return try JSONDecoder().decode(Sidecar.self, from: data)
            } catch {
                ErrorTracker.shared.add(error)
                return nil
            }
        }
        
        private func _document() throws -> Data {
            try Data(contentsOf: documentURL)
        }
    }
}
