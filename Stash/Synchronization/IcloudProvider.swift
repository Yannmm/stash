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
        
        private let monitor = IcloudContainerMonitor(filename: Constant.sidecarFileName)
        
        private let pieceSaver = PieceSaver()
        
        private let _onFileChange = PassthroughSubject<Result<URL, Error>, Never>()
        
        var onFileChange: AnyPublisher<Result<URL, Error>, Never> { _onFileChange.eraseToAnyPublisher() }
        
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
                        if let saved: String? = self.pieceSaver.value(for: .appIdentifier) {
                            return incoming != saved
                        }
                        return true
                    })
                    .delay(for: .seconds(2), scheduler: RunLoop.main)
                    .sink(receiveValue: { [weak self] identifier in
                        guard let this = self else { return }
                        this.pieceSaver.save(for: .appIdentifier, value: identifier)
                        do {
                            this._onFileChange.send(.success(try this.getDocumentFilePath()))
                        } catch {
                            this._onFileChange.send(.failure(error))
                        }
                    })
                
                monitor.start()
            } else {
                monitor.stop()
                monitorHandle?.cancel()
                monitorHandle = nil
            }
        }
        
        private func getDocumentFilePath() throws -> URL {
            let mgr = FileManager.default
            
            guard let container = mgr.url(forUbiquityContainerIdentifier: nil) else { throw SomeError.icloudContainerUnavailable  }
            
            let documents = container.appendingPathComponent("Documents")
            
            if !mgr.fileExists(atPath: documents.path) {
                try mgr.createDirectory(at: documents, withIntermediateDirectories: true, attributes: nil)
            }
            
            return documents.appendingPathComponent(Constant.contentFileName)
        }
    }
}

extension Synchronizer.IcloudProvider {
    enum SomeError: Error, LocalizedError {
        case icloudContainerUnavailable
    }
}
