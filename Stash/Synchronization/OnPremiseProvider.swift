//
//  LocalProvider.swift
//  Stash
//
//  Created by Yan Meng on 2026/5/26.
//

import Foundation
import Combine

extension Synchronizer {
    final class OnPremiseProvider: Provider {
        static func initialize() async throws -> Synchronizer.OnPremiseProvider {
            return OnPremiseProvider()
        }
        
        private let pieceSaver = PieceSaver()
        
        private init() {}
        
        var onFileChange: AnyPublisher<Result<URL, Error>, Never> { _onFileChange.eraseToAnyPublisher() }
        
        private let _onFileChange = PassthroughSubject<Result<URL, Error>, Never>()
        
        func save(document html: String) async throws {
            let paths = try getPaths()
            try html.write(to: paths.document, atomically: true, encoding: .utf8)
            // TODO: do I need to rewrite to picecsave a new uuid if it does not exist??
            if let appId = pieceSaver.value(for: PieceSaver.Key.appIdentifier) {
                try appId.write(to: paths.sidecar, atomically: true, encoding: .utf8)
            }
        }
        
        func load() throws -> String {
            let paths = try getPaths()
            return try String(contentsOf: paths.document, encoding: .utf8)
        }
        
        private func getPaths() throws -> Paths {
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

extension Synchronizer.OnPremiseProvider {
    enum SomeError: Error, LocalizedError {
        case missingApplicationSupportDirectory
    }
}
