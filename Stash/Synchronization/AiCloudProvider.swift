//
//  AiCloudProvider.swift
//  Stash
//
//  Created by Rayman on 2026/5/11.
//

import Foundation
import Combine

extension Synchronizer {
    final class AiCloudProvider: Provider {
        private let _onArrive = PassthroughSubject<Sidecar, Never>()
        var onArrive: AnyPublisher<Sidecar, Never> { _onArrive.eraseToAnyPublisher() }
        
        var availability: AnyPublisher<Availability, Never> { _availability.eraseToAnyPublisher() }
        private let _availability = CurrentValueSubject<Availability, Never>(.pending)

        private let monitor = AiCloudContainerMonitor(filename: FileName.sidecar)
        private var monitorHandle: AnyCancellable?

        init() {}

        deinit {
            stopMonitor()
        }

        // MARK: - Protocol
        @discardableResult
        func checkAvailability() async -> Availability {
            let available = await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .utility).async {
                    let url = FileManager.default.url(forUbiquityContainerIdentifier: nil)
                    continuation.resume(returning: url != nil)
                }
            }
            let a: Availability = available ? .yes : .no(ProviderError.icloudContainerUnavailable)
            defer { _availability.send(a) }
            return a
        }

        func sidecar() async throws -> Sidecar {
            let url = try sidecarURL()
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(Sidecar.self, from: data)
        }

        func document() async throws -> Data {
            let url = try documentURL()
            return try Data(contentsOf: url)
        }

        func send(document: Data, sidecar: Sidecar) async throws {
            let docURL = try documentURL()
            let scURL = try sidecarURL()
            try document.write(to: docURL, options: .atomic)
            let sidecarData = try JSONEncoder().encode(sidecar)
            try sidecarData.write(to: scURL, options: .atomic)
        }

        func prepare() async throws {
            startMonitor()
            await checkAvailability()
        }

        func pause() async throws {
            stopMonitor()
        }

        // MARK: - Monitor

        private func startMonitor() {
            monitorHandle = monitor.$onChange
                .compactMap { $0 }
                .delay(for: .seconds(2), scheduler: RunLoop.main)
                .sink { [weak self] _ in
                    guard let self else { return }
                    do {
                        let url = try self.sidecarURL()
                        let data = try Data(contentsOf: url)
                        let sidecar = try JSONDecoder().decode(Sidecar.self, from: data)
                        self._onArrive.send(sidecar)
                    } catch {
                        print("[iCloud] failed to parse incoming sidecar: \(error)")
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
                throw ProviderError.icloudContainerUnavailable
            }
            let documents = container.appendingPathComponent("Documents")
            if !FileManager.default.fileExists(atPath: documents.path) {
                try FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
            }
            return documents
        }

        private func documentURL() throws -> URL {
            try containerDocumentsURL().appendingPathComponent(FileName.document)
        }

        private func sidecarURL() throws -> URL {
            try containerDocumentsURL().appendingPathComponent(FileName.sidecar)
        }
    }
}

extension Synchronizer.AiCloudProvider {
    enum ProviderError: Error, LocalizedError {
        case icloudContainerUnavailable

        var errorDescription: String? {
            switch self {
            case .icloudContainerUnavailable:
                return "iCloud container is not available"
            }
        }
    }
}
