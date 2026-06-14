//
//  Synchronizer.swift
//  Stash
//
//  Created by Rayman on 2026/5/11.
//

import Foundation
import Combine

class Synchronizer {
    private var provider: Synchronizer.Provider?
    private let pieceSaver: PieceSaver
    private var sidecarMonitor: FileMonitor!
    private var cancellables = Set<AnyCancellable>()
    
    private var _approach: Approach? {
//        didSet {
//            guard oldValue != approach else { return }
//            spawnProvider()
//        }
    }
    
    var getApproach: Approach {
        
    }
    
    init(pieceSaver: PieceSaver) {
        self.pieceSaver = pieceSaver
        self.approach = pieceSaver.value(for: PieceSaver.Key.synchronizerApproach) ?? .local
        
        let paths = try! getPaths()
        self.sidecarMonitor = FileMonitor(paths.sidecar)
        bind()
        
        sidecarMonitor.start()
    }
    
    // TODO: always write to pref before update local sidecar file when update within the current app
    
    private func bind() {
        sidecarMonitor.onChange
            .tryMap({ try String(contentsOf: $0, encoding: .utf8) })
            .catch { error -> AnyPublisher<String, Never> in
                ErrorTracker.shared.add(error)
                return Empty().eraseToAnyPublisher()
            }
            .filter { [weak self] event in
                let appid = self?.pieceSaver.value(for: PieceSaver.Key.appIdentifier) ?? ""
                return appid == event
            }
//            .delay(for: .seconds(2), scheduler: RunLoop.main)
            .sink { x in
                guard let p = self.provider else { return }
                Task {
                    do {
                        try await p.synchronize(source: try self.getPaths())
                    } catch {
                        print("there is error \(error)")
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func save(document html: String) async throws {
        let paths = try getPaths()
        try html.write(to: paths.document, atomically: true, encoding: .utf8)
        let appid = UUID().uuidString
        pieceSaver.save(for: PieceSaver.Key.appIdentifier, value: appid)
        try appid.write(to: paths.sidecar, atomically: true, encoding: .utf8)
    }
    
    func load() throws -> String {
        let paths = try getPaths()
        
        let xx = Synchronizer.Approach(rawValue: "xx")
        return try String(contentsOf: paths.document, encoding: .utf8)
    }
    
    private func spawnProvider() {
        Task {
            do {
                try self.provider?.dispose()
                switch approach {
                case .icloud:
                    self.provider = try await IcloudProvider.initialize()
                case .local:
                    self.provider = nil
                case .dropbox:
                    fatalError("Not impelmented")
                }
                
                try await self.provider?.synchronize(source: try self.getPaths())
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
        
        func dispose() throws
        
        /// Synchronize down
        var onRemoteChange: AnyPublisher<Result<URL, Error>, Never> { get }
        
        /// Synchronize up
        func synchronize(source: Paths) async throws
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
    
    enum Status {
        case checking
        case available
        case unavailable(Error?)
    }
    
    enum FileName {
        static let document = "nustash_index.html"
        static let sidecar = "nustash_index.html.sidecar"
    }
    
    struct 
}
