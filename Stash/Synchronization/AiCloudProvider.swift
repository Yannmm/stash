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
        
        private var monitorHandle: AnyCancellable?
        
        private let monitor = AiCloudContainerMonitor(filename: FileName.sidecar)
        
        private let _incoming = PassthroughSubject<Result<Paths, Error>, Never>()
        
        var incoming: AnyPublisher<Result<Paths, Error>, Never> { _incoming.eraseToAnyPublisher() }
        
        private let _available = PassthroughSubject<Availability, Never>()
        
        var available: AnyPublisher<Synchronizer.Availability, Never> { _available.eraseToAnyPublisher() }
        
        func prepare() async throws {
            checkAvailability()
            monitor(true)
        }
        
        func pause() async throws {
            monitor(false)
        }
        
        init() {}
        
        deinit {
            monitor(false)
        }
        
        
        
        static func initialize() async throws -> Synchronizer.AiCloudProvider {
            let available = await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .utility).async {
                    let url = FileManager.default.url(forUbiquityContainerIdentifier: nil)
                    continuation.resume(returning: url != nil)
                }
            }
            if available {
                return AiCloudProvider()
            } else {
                throw SomeError.icloudContainerUnavailable
            }
        }
        
        private func checkAvailability() {
            Task {
                _available.send(.checking)
                let available = await withCheckedContinuation { continuation in
                    DispatchQueue.global(qos: .utility).async {
                        let url = FileManager.default.url(forUbiquityContainerIdentifier: nil)
                        continuation.resume(returning: url != nil)
                    }
                }
                if available {
                    _available.send(.yes)
                } else {
                    _available.send(.no(SomeError.icloudContainerUnavailable))
                }
            }
        }
        
        func monitor(_ start: Bool) {
            if start {
                monitorHandle = monitor.$onChange
                    .compactMap({ $0 })
                    .tryMap({ try String(contentsOf: $0, encoding: .utf8) })
                    .catch { error -> AnyPublisher<String, Never> in
                        ErrorTracker.shared.add(error)
                        return Empty().eraseToAnyPublisher()
                    }
                    .filter({ incoming in
                        if let saved = Pref.value(for: Pref.Key.appIdentifier) {
                            return incoming != saved
                        }
                        return true
                    })
                    .delay(for: .seconds(2), scheduler: RunLoop.main)
                    .sink(receiveValue: { [weak self] identifier in
                        guard let this = self else { return }
                        Pref.save(for: Pref.Key.appIdentifier, value: identifier)
                        do {
                            let paths = try this.getPaths()
                            this._incoming.send(.success(paths))
                        } catch {
                            this._incoming.send(.failure(error))
                        }
                    })
                
                monitor.start()
            } else {
                monitor.stop()
                monitorHandle?.cancel()
                monitorHandle = nil
            }
        }
        
        func getPaths() throws -> Paths {
            let mgr = FileManager.default
            
            guard let container = mgr.url(forUbiquityContainerIdentifier: nil) else { throw SomeError.icloudContainerUnavailable  }
            
            let documents = container.appendingPathComponent("Documents")
            
            if !mgr.fileExists(atPath: documents.path) {
                try mgr.createDirectory(at: documents, withIntermediateDirectories: true, attributes: nil)
            }
            
            return Paths(document: documents.appendingPathComponent(FileName.document), sidecar: documents.appendingPathComponent(FileName.sidecar))
        }
    }
}

extension Synchronizer.AiCloudProvider {
    enum SomeError: Error, LocalizedError {
        case icloudContainerUnavailable
    }
}


