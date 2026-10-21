//
//  AiCloudProvider.swift
//  Stash
//
//  Created by Rayman on 2026/5/11.
//

import Foundation
import Combine

extension Synchronizer {
    final class AiCloudProvider: RemoteProvider {
        var readiness: AnyPublisher<Result<any ProviderReadiness, Error>, Never> {
            _reachability.eraseToReadinessPublisher()
        }
        
        private let _reachability = CurrentValueSubject<Result<UbiquityContainerReachability, Error>, Never>(.success(.indetermined))
        
        var strayError: AnyPublisher<(String, Error)?, Never> { _strayError.eraseToAnyPublisher() }
        
        private let _strayError = PassthroughSubject<(String, Error)?, Never>()
        
        var onArrive: AnyPublisher<Sidecar, Never> { _onArrive.eraseToAnyPublisher() }
        
        private let _onArrive = PassthroughSubject<Sidecar, Never>()
        
        private let monitor = AiCloudContainerMonitor(filename: FileName.sidecar)
        
        private var monitorHandle: AnyCancellable?
        
        // MARK: - Protocol
        func checkAvailable() async {
            let flag = await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .utility).async {
                    let url = FileManager.default.url(forUbiquityContainerIdentifier: nil)
                    continuation.resume(returning: url != nil)
                }
            }
            _reachability.send(flag ? .success(.yes) : .failure(SyncError.ubiquityContainerInaccessible))
        }
        
        func sidecar() async throws -> Sidecar {
            let data = try Data(contentsOf: try sidecarUrl())
            return try JSONDecoder().decode(Sidecar.self, from: data)
        }
        
        func document() async throws -> Data {
            return try Data(contentsOf: try documentUrl())
        }
        
        func send(document: Data, sidecar: Sidecar) async throws {
            try document.write(to: try documentUrl(), options: .atomic)
            let sidecarData = try JSONEncoder().encode(sidecar)
            try sidecarData.write(to: try sidecarUrl(), options: .atomic)
        }
        
        func prepare() async throws {
            startMonitor()
            await checkAvailable()
        }
        
        func pause() async throws {
            stopMonitor()
            await checkAvailable()
        }
        
        // MARK: - Monitor
        
        private func startMonitor() {
            monitorHandle = monitor.$onChange
                .compactMap { $0 }
                .delay(for: .seconds(2), scheduler: RunLoop.main)
                .sink { [weak self] _ in
                    guard let self else { return }
                    do {
                        let data = try Data(contentsOf: try self.sidecarUrl())
                        let sidecar = try JSONDecoder().decode(Sidecar.self, from: data)
                        self._onArrive.send(sidecar)
                    } catch {
                        _strayError.send(("icloud monitor", error))
                    }
                }
            monitor.start()
        }
        
        private func stopMonitor() {
            monitor.stop()
            monitorHandle?.cancel()
            monitorHandle = nil
        }
        
        // MARK: - Paths
        
        private func containerDocumentsURL() throws -> URL {
            guard let container = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
                throw SyncError.ubiquityContainerInaccessible
            }
            let documents = container.appendingPathComponent("Documents")
            if !FileManager.default.fileExists(atPath: documents.path) {
                try FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
            }
            return documents
        }
        
        private func documentUrl() throws -> URL {
            try containerDocumentsURL().appendingPathComponent(FileName.document)
        }
        
        private func sidecarUrl() throws -> URL {
            try containerDocumentsURL().appendingPathComponent(FileName.sidecar)
        }
        
        deinit {
            stopMonitor()
        }
    }
}
