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
        private let _availability = CurrentValueSubject<Availability, Never>(.no(InitialPendingState(name: "iCloud")))
        
        private let monitor = AiCloudContainerMonitor(filename: FileName.sidecar)
        private var monitorHandle: AnyCancellable?
        
        init() {}
        
        deinit {
            stopMonitor()
        }
        
        // MARK: - Protocol
        func checkAvailability() async {
            let available = await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .utility).async {
                    let url = FileManager.default.url(forUbiquityContainerIdentifier: nil)
                    continuation.resume(returning: url != nil)
                }
            }
            let a: Availability = available ? .yes(raedyMessage) : .no(SomeError.unsupported)
            _availability.send(a)
        }
        
        func sidecar() async throws -> Sidecar? {
            guard let url = try sidecarURL() else {
                return nil
            }
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(Sidecar.self, from: data)
        }
        
        func document() async throws -> Data? {
            guard let url = try documentURL() else {
                return nil
            }
            return try Data(contentsOf: url)
        }
        
        func send(document: Data, sidecar: Sidecar) async throws {
            guard
                let durl = try documentURL(),
                let surl = try sidecarURL() else {
                return
            }
            try document.write(to: durl, options: .atomic)
            let sidecarData = try JSONEncoder().encode(sidecar)
            try sidecarData.write(to: surl, options: .atomic)
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
                        guard let url = try self.sidecarURL() else {
                            return
                        }
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
        
        private func containerDocumentsURL() throws -> URL? {
            guard let container = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
                _availability.send(.no(SomeError.unsupported))
                return nil
            }
            let documents = container.appendingPathComponent("Documents")
            if !FileManager.default.fileExists(atPath: documents.path) {
                try FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
            }
            return documents
        }
        
        private func documentURL() throws -> URL? {
            try containerDocumentsURL()?.appendingPathComponent(FileName.document)
        }
        
        private func sidecarURL() throws -> URL? {
            try containerDocumentsURL()?.appendingPathComponent(FileName.sidecar)
        }
    }
}

extension Synchronizer.AiCloudProvider {
    enum SomeError: Error, Synchronizer.Descriptor {
        case unsupported
        case corruptData(Error)
        
        func describe() -> AttributedString {
            var attr: AttributedString!
            switch self {
            case .unsupported:
                attr = AttributedString("iCloud is not available.")
            case .corruptData(let error):
                attr = AttributedString(error.localizedDescription)
            }
            attr.foregroundColor = .red
            return attr
        }
    }
    
    var raedyMessage: AttributedString {
        var attr = AttributedString("iCloud is ready.")
        attr.foregroundColor = .secondary
        return attr
    }
}



