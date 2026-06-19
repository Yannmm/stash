//
//  Synchronizer.swift
//  Stash
//
//  Created by Rayman on 2026/5/11.
//

import Foundation
import Combine

class Synchronizer {
    var approach: Approach! {
        didSet {
            Task {
                do {
//                    try self.currentProvider?.dispose()
//                    switch approach {
//                    case .icloud:
//                        self.provider = try await AiCloudProvider.initialize()
//                    case .local:
//                        self.provider = nil
//                    case .dropbox:
//                        fatalError("Not impelmented")
//                    }
                    try await self.selection.provider.synchronize(source: try self.getPaths())
                } catch {
                    // TODO: handle initialize failure error. alert user or reinitailize???
                    print("there is an error: \(error)")
                }
            }
        }
    }
    
    private let pieceSaver: PieceSaver
    
    private var sidecarMonitor: FileMonitor!
    
    private var cancellables = Set<AnyCancellable>()
    
    private var providers: [Approach: any Provider]
    
    private var availabilities: [Approach: Availability]!
    
    var selection: Selection { Selection(approach: approach, available: availabilities[approach]!, provider: providers[approach]!) }
 
    init(providers: [Approach: any Provider], pieceSaver: PieceSaver) {
        self.pieceSaver = pieceSaver
        self.providers = providers
        self.availabilities = providers.mapValues({ _ in Availability.checking })
        
        let paths = try! getPaths()
        self.sidecarMonitor = FileMonitor(paths.sidecar)
        bind()
        
        sidecarMonitor.start()
    }
    
    // TODO: always write to pref before update local sidecar file when update within the current app
    
    private func bind() {
        for x in providers {
            let a = x.value.available.sink { a in
                self.availabilities[x.key] = a
            }
        }
        
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
                let selection = self.selection
                guard selection.available == .yes else { return }
                Task {
                    do {
                        try await selection.provider.synchronize(source: try self.getPaths())
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
        return try String(contentsOf: paths.document, encoding: .utf8)
    }
    
//    private func spawnProvider() {
//        Task {
//            do {
//                try self.currentProvider?.dispose()
//                switch approach {
//                case .icloud:
//                    self.provider = try await AiCloudProvider.initialize()
//                case .local:
//                    self.provider = nil
//                case .dropbox:
//                    fatalError("Not impelmented")
//                }
//                
//                try await self.provider?.synchronize(source: try self.getPaths())
//            } catch {
//                // TODO: handle initialize failure error. alert user or reinitailize???
//                print("there is an error: \(error)")
//            }
//        }
//    }
    
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
//        static func initialize() async throws -> Self
        
//        func dispose() throws
        
        /// Synchronize down
        var onRemoteChange: AnyPublisher<Result<URL, Error>, Never> { get }
        
        /// Synchronize up
        func synchronize(source: Paths) async throws
        
//        func available() async -> Availability
        
        var available: AnyPublisher<Availability, Never> { get }
        
        func prepare() async throws
//            func start or prepare?? to start monitor etc, it may throw an
            // monitor file
            // ask user to signin
            // etc
        
        
        func pause() async throws
    }
    
    struct Paths {
        let document: URL
        let sidecar: URL
    }
    
    enum FileName {
        static let document = "nustash_index.html"
        static let sidecar = "nustash_index.html.sidecar"
    }
    
    enum Approach: String, CaseIterable, Identifiable {
        var id: String { rawValue }
        
        case icloud
        case local
        case dropbox
    }
    
    enum Availability: Equatable {
        static func == (lhs: Synchronizer.Availability, rhs: Synchronizer.Availability) -> Bool {
            switch (lhs, rhs) {
            case (.checking, .checking):
                return true
            case (.yes, .yes):
                return true
            case (.no(_), .no(_)):
                return true
            default:
                return false
            }
        }
        
        
        
        case checking
        case yes
        case no(Error?)
    }
    
    struct Selection {
        let approach: Approach
        let available: Availability
        let provider: Provider
    }
}
