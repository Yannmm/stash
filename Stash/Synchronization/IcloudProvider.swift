//
//  IcloudProvider.swift
//  Stash
//
//  Created by Rayman on 2026/5/11.
//

import Foundation
import Combine

extension Synchronizer {
    final class IcloudProvider: Provider {
        private var monitorHandle: AnyCancellable?
        
        private let monitor = IcloudContainerMonitor(filename: FileName.sidecar)
        
        private let pieceSaver = PieceSaver()
        
        private let _onRemoteChange = PassthroughSubject<Result<URL, Error>, Never>()
        
        var onRemoteChange: AnyPublisher<Result<URL, Error>, Never> { _onRemoteChange.eraseToAnyPublisher() }
        
        private init() {
            monitor(true)
        }
        
        deinit {
            monitor(false)
        }
        
        static func initialize() async throws -> Synchronizer.IcloudProvider {
            let available = await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .utility).async {
                    let url = FileManager.default.url(forUbiquityContainerIdentifier: nil)
                    continuation.resume(returning: url != nil)
                }
            }
            if available {
                return IcloudProvider()
            } else {
                throw SomeError.icloudContainerUnavailable
            }
        }
        
        func dispose() throws {
            monitor(false)
        }
        
        func synchronize(source: Paths) async throws {
            let paths = try getPaths()
            try await FileHelper.replaceFile(from: source.document, to: paths.document)
            try await FileHelper.replaceFile(from: source.sidecar, to: paths.sidecar)
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
                        if let saved = self.pieceSaver.value(for: PieceSaver.Key.appIdentifier) {
                            return incoming != saved
                        }
                        return true
                    })
                    .delay(for: .seconds(2), scheduler: RunLoop.main)
                    .sink(receiveValue: { [weak self] identifier in
                        guard let this = self else { return }
                        this.pieceSaver.save(for: PieceSaver.Key.appIdentifier, value: identifier)
                        do {
                            let paths = try this.getPaths()
                            this._onRemoteChange.send(.success(paths.document))
                        } catch {
                            this._onRemoteChange.send(.failure(error))
                        }
                    })
                
                monitor.start()
            } else {
                monitor.stop()
                monitorHandle?.cancel()
                monitorHandle = nil
            }
        }
        
        private func getPaths() throws -> Paths {
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

extension Synchronizer.IcloudProvider {
    enum SomeError: Error, LocalizedError {
        case icloudContainerUnavailable
    }
}


