import Foundation
import Combine

extension Synchronizer {
    final class OnPremiseProvider: LocalProvider {
        var onArrive: AnyPublisher<Sidecar, Never> { _onArrive.eraseToAnyPublisher() }
        
        private let _onArrive = PassthroughSubject<Sidecar, Never>()
        
        private let directory: URL
        
        init() {
            let fmgr = FileManager.default
            let support = fmgr.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            directory = support.appendingPathComponent("Stash", isDirectory: true)
        }
                
        // MARK: - Protocol conformance
        
        func prepare() async throws {
            let fmgr = FileManager.default
            if !fmgr.fileExists(atPath: directory.path) {
                try fmgr.createDirectory(at: directory, withIntermediateDirectories: true)
            }
        }
        
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
        
        @discardableResult
        func write(html: String) throws -> Sidecar {
            guard let data1 = html.data(using: .utf8) else {
                throw SyncError.malformatString(html)
            }
            try data1.write(to: documentURL, options: .atomic)
            let sidecar = Sidecar.stamp()
            let data2 = try JSONEncoder().encode(sidecar)
            try data2.write(to: sidecarUrl, options: .atomic)
            return sidecar
        }
        
        // MARK: - Helper
        
        private var documentURL: URL {
            directory.appendingPathComponent(FileName.document)
        }
        
        private var sidecarUrl: URL {
            directory.appendingPathComponent(FileName.sidecar)
        }
        
        private func _sidecar() throws -> Sidecar {
            do {
                let data = try Data(contentsOf: sidecarUrl)
                return try JSONDecoder().decode(Sidecar.self, from: data)
            } catch let error as NSError
                where error.domain == NSCocoaErrorDomain &&
                        (error.code == NSFileNoSuchFileError ||
                         error.code == NSFileReadNoSuchFileError) {
                throw SyncError.fileNotFound(sidecarUrl.absoluteString)
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
                throw SyncError.fileNotFound(sidecarUrl.absoluteString)
            } catch {
                throw error
            }
        }
    }
}
