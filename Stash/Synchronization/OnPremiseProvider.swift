import Foundation
import Combine

extension Synchronizer {
    final class OnPremiseProvider: LocalProvider {
        private let _onArrive = PassthroughSubject<Sidecar, Never>()
        
        var onArrive: AnyPublisher<Sidecar, Never> { _onArrive.eraseToAnyPublisher() }
        
        var availability: AnyPublisher<Availability, Never> { Just(.yes(message)).eraseToAnyPublisher() }
        
        func getAvailability() async -> Availability { .yes(message) }
        
        private let directory: URL
        
        init() {
            let fmgr = FileManager.default
            let support = fmgr.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            directory = support.appendingPathComponent("Stash", isDirectory: true)
            do {
                if !fmgr.fileExists(atPath: directory.path) {
                    try fmgr.createDirectory(at: directory, withIntermediateDirectories: true)
                }
            } catch {
                ErrorTracker.shared.add(error)
            }
        }
        
        private var documentURL: URL {
            directory.appendingPathComponent(FileName.document)
        }
        
        private var sidecarUrl: URL {
            directory.appendingPathComponent(FileName.sidecar)
        }
        
        // MARK: - Protocol conformance
        
        func sidecar() async throws -> Sidecar {
            try _sidecar()
        }
        
        func document() async throws -> Data {
            try _document()
        }
        
        func copy(document: Data, sidecar: Sidecar) async throws {
            try document.write(to: documentURL, options: .atomic)
            let sidecarData = try JSONEncoder().encode(sidecar)
            try sidecarData.write(to: sidecarUrl, options: .atomic)
            _onArrive.send(sidecar)
        }
        
        // MARK: - Non-protocol
        @discardableResult
        func write(html: String) throws -> Sidecar {
            guard let data1 = html.data(using: .utf8) else {
                throw SomeError.corruptData(html)
            }
            try data1.write(to: documentURL, options: .atomic)
            let sidecar = Sidecar.stamp()
            let data2 = try JSONEncoder().encode(sidecar)
            try data2.write(to: sidecarUrl, options: .atomic)
            return sidecar
        }
        
        private func _sidecar() throws -> Sidecar {
            do {
                let data = try Data(contentsOf: sidecarUrl)
                return try JSONDecoder().decode(Sidecar.self, from: data)
            } catch let error as NSError
                where error.domain == NSCocoaErrorDomain &&
                        (error.code == NSFileNoSuchFileError ||
                         error.code == NSFileReadNoSuchFileError) {
                throw SomeError.fileNotFound(sidecarUrl)
            } catch {
                throw error
            }
        }
        
        private func _document() throws -> Data {
            do {
                return try Data(contentsOf: documentURL)
            } catch let error as NSError
                where error.domain == NSCocoaErrorDomain &&
                      error.code == NSFileNoSuchFileError {
                throw SomeError.fileNotFound(sidecarUrl)
            } catch {
                throw error
            }
        }
        
        private var message: AttributedString {
            var attr = AttributedString("Select other approach to synchronize across devices.")
            attr.foregroundColor = .secondary
            return attr
        }
    }
}

extension Synchronizer.OnPremiseProvider {
    enum SomeError: Error {
        case fileNotFound(URL)
        case corruptData(String)
    }
}
