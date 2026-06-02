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
    private var localSidecarMonitor: FileMonitor!
    
    var approach: Approach {
        didSet {
            guard oldValue != approach else { return }
            spawnProvider()
        }
    }
    
    init(pieceSaver: PieceSaver) {
        self.pieceSaver = pieceSaver
        self.approach = pieceSaver.value(for: PieceSaver.Key.synchronizerApproach) ?? .local
        
        
        // TODO: set up listener to local file so that each time sidecar change, use provdre to save as well
        
        
        let paths = try! getPaths()
        self.localSidecarMonitor = FileMonitor(paths.sidecar)
//        let monitor = FileMonitor(paths.sidecar) {
//            // 1. 读取pref里面的 uuid 进行比较
//            let appId: String = pieceSaver.value(for: PieceSaver.Key.appIdentifier)
//        }

        bind()
        
        localSidecarMonitor.start()
    }
    
    // TODO: always write to pref before update local sidecar file when update within the current app
    
    private func bind() {
        localSidecarMonitor.onChange
            .tryMap({ try String(contentsOf: $0, encoding: .utf8) })
            .catch { error -> AnyPublisher<String, Never> in
                ErrorTracker.shared.add(error)
                return Empty().eraseToAnyPublisher()
            }
            .filter { [weak self] event in
                if let appid = self?.pieceSaver.value(for: PieceSaver.Key.appIdentifier) {
                    return appid != event
                } else {
                    return true
                }
            }
            .delay(for: .seconds(2), scheduler: RunLoop.main)
            .sink { x in
                // TODO: sync via provider
            }
    }
    
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
                let paths = try getPaths()
                let xx = try String(contentsOf: paths.document, encoding: .utf8)
                
                try await self.provider.save(document: xx)
            } catch {
                // TODO: handle initialize failure error. alert user or reinitailize???
                print("there is an error: \(error)")
            }
        }
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
    
    enum SomeError: Error, LocalizedError {
        case missingApplicationSupportDirectory
    }
}

extension Synchronizer {
    protocol Provider {
        static func initialize() async throws -> Self
        
        // TODO: 这个方法似乎应该去除，某些provider会有 file （icloud）， 但某些没有，或者不应该常驻，如 dropbox 和 icloud
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
