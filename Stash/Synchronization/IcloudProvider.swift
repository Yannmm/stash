//
//  IcloudProvider.swift
//  Stash
//
//  Created by Rayman on 2026/5/11.
//

import Foundation
import Combine

extension Synchronizer {
    class IcloudProvider: Provider {
        
        private var icloudMonitorSubscription: AnyCancellable?
        
        
        private let icloudMonitor = IcloudFileMonitor(filename: Constant.sidecarFileName)
        
        private let pieceSaver = PieceSaver()
        
        func prepare() {
            // TODO: I should determine whether icloud is usable beofre creating monitor and even icloud provider
        }
        
        func monitor(_ start: Bool) {
            if start {
                icloudMonitorSubscription = icloudMonitor.$onChange
                    .compactMap({ $0 })
                    .tryMap({ try String(contentsOf: $0, encoding: .utf8) })
                    .catch { error -> AnyPublisher<String, Never> in
                        ErrorTracker.shared.add(error)
                        return Empty().eraseToAnyPublisher()
                    }
                    .map({ UUID(uuidString: $0) })
                    .combineLatest(Just<String?>(pieceSaver.value(for: .appIdentifier))
                        .compactMap({ $0 })
                        .map({ UUID(uuidString: $0) }))
                    .filter({ $0.0 != $0.1 })
                    .delay(for: .seconds(2), scheduler: RunLoop.main)
                    .sink(receiveValue: { [weak self] _ in
//                        self?.load()
                        // TODO: load from the right file
                    })

                icloudMonitor.start()
            } else {
                icloudMonitor.stop()
                icloudMonitorSubscription?.cancel()
            }
        }
        
        func getPaths() throws -> Paths {
            let fileManager = FileManager.default
            
            guard let container = fileManager.url(forUbiquityContainerIdentifier: nil) else { throw SomeError.icloudContainerUnavailable  }
            
            let documents = container.appendingPathComponent("Documents")
            
            if !fileManager.fileExists(atPath: documents.path) {
                try fileManager.createDirectory(at: documents, withIntermediateDirectories: true, attributes: nil)
            }
            
            return Paths(
                document: documents.appendingPathComponent(Constant.stashFileName),
                sidecar: documents.appendingPathComponent(Constant.sidecarFileName)
            )
        }
    }
}

extension Synchronizer.IcloudProvider {
    enum SomeError: Error, LocalizedError {
        case icloudContainerUnavailable
    }
    
    enum Constant {
        static let stashFileName = "default.html"
        static let sidecarFileName = "default.html.sidecar"
    }
}
