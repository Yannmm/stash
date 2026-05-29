//
//  Synchronizer.swift
//  Stash
//
//  Created by Rayman on 2026/5/11.
//

import Foundation
import Combine

class Synchronizer {
    private var provider: Synchronizer.Provider!
    
    private let pieceSaver: PieceSaver
    
    var approach: Approach {
        didSet {
            guard oldValue != approach else { return }
            spawnProvider()
        }
    }
    
    init(pieceSaver: PieceSaver) {
        self.pieceSaver = pieceSaver
        self.approach = pieceSaver.value(for: .synchronizerApproach) ?? .local
        
        // TODO: set up listener to local file so that each time sidecar change, use provdre to save as well
    }
    
    func save(document html: String) async throws {
        let paths = try getLocalPaths()
        try html.write(to: paths.document, atomically: true, encoding: .utf8)
        // TODO: do I need to rewrite to picecsave a new uuid if it does not exist??
        if let appId: String = pieceSaver.value(for: .appIdentifier) {
            try appId.write(to: paths.sidecar, atomically: true, encoding: .utf8)
        }
    }
    
    func load() throws -> String {
        let paths = try getLocalPaths()
        return try String(contentsOf: paths.document, encoding: .utf8)
    }
    
    private func spawnProvider() {
        Task {
            do {
                switch approach {
                case .icloud:
                    self.provider = try await IcloudProvider.initialize()
                case .local:
                    self.provider = try await OnPremiseProvider.initialize()
                case .dropbox:
                    fatalError("Not impelmented")
                }
                
                // TODO: common local paths
                let paths = try getLocalPaths()
                let xx = try String(contentsOf: paths.document, encoding: .utf8)
                
                try await self.provider.save(document: xx)
            } catch {
                // TODO: handle initialize failure error. alert user or reinitailize???
                print("there is an error: \(error)")
            }
        }
    }
    
    private func getLocalPaths() throws -> Paths {
        let fileManager = FileManager.default
        guard let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { throw SomeError.missingApplicationSupportDirectory}
        let direcotry = support.appendingPathComponent("Stash", isDirectory: true)
        if !fileManager.fileExists(atPath: direcotry.path) {
            try fileManager.createDirectory(at: direcotry, withIntermediateDirectories: true, attributes: nil)
        }
        return Paths(document: direcotry.appendingPathComponent(Synchronizer.FileName.document), sidecar: direcotry.appendingPathComponent(Synchronizer.FileName.sidecar))
    }
    
    enum SomeError: Error, LocalizedError {
        case missingApplicationSupportDirectory
    }
}

extension Synchronizer {
    protocol Provider {
        static func initialize() async throws -> Self
        
        var onFileChange: AnyPublisher<Result<URL, Error>, Never> { get }
        
        func save(document html: String) async throws
        
        func load() throws -> String
    }
    
    struct Paths {
        let document: URL
        let sidecar: URL
    }
    
    enum Approach: String, CaseIterable, Identifiable {
        var id: String { rawValue }
        
        case icloud
        case local
        case dropbox
    }
    
    enum FileName {
        static let document = "default.html"
        static let sidecar = "default.html.sidecar"
    }
}
