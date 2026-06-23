//
//  LocalStorageProvider.swift
//  Stash
//
//  Created by Yan Meng on 2026/6/18.
//

import Combine
import Foundation

extension Synchronizer {
    final class LocalStorageProvider: Provider {
        init() {}
        
        var incoming: AnyPublisher<Result<Paths, Error>, Never> { Empty(completeImmediately: false)
            .eraseToAnyPublisher() }
        
        var available: AnyPublisher<Synchronizer.Availability, Never> { Just(.yes).eraseToAnyPublisher() }
        
        func prepare() async throws {
            // Noop
        }
        
        func pause() async throws {
            // Noop
        }
        
        func getPaths() throws -> Paths {
            let fileManager = FileManager.default
            guard let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { throw SomeError.missingApplicationSupportDirectory}
            let direcotry = support.appendingPathComponent("Stash", isDirectory: true)
            if !fileManager.fileExists(atPath: direcotry.path) {
                try fileManager.createDirectory(at: direcotry, withIntermediateDirectories: true, attributes: nil)
            }
            return Paths(document: direcotry.appendingPathComponent(Synchronizer.FileName.document), sidecar: direcotry.appendingPathComponent(Synchronizer.FileName.sidecar))
        }
    }
}
