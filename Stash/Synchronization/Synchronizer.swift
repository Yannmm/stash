//
//  Synchronizer.swift
//  Stash
//
//  Created by Rayman on 2026/5/11.
//

import Foundation
import Combine

class Synchronizer {
    var approach: Option {
        didSet {
            Task {
                do {
                    try await self.selection.provider.send(content: .file(try self.localStorageProvider.getPaths()))
                } catch {
                    // TODO: handle initialize failure error. alert user or reinitailize???
                    print("there is an error: \(error)")
                }
            }
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private var providers: [Option: any Provider]
    
    private var availabilities: [Option: Availability]!
    
    var selection: Selection { Selection(approach: approach, available: availabilities[approach]!, provider: providers[approach]!) }
    
    private var localStorageProvider: Provider!
 
    init(approach: Option, providers: [Option: any Provider]) {
        self.approach = approach
        self.providers = providers
        self.availabilities = providers.mapValues({ _ in Availability.checking })
        self.localStorageProvider = providers[.local] ?? LocalStorageProvider()
        bind()
    }
    
    // TODO: always write to pref before update local sidecar file when update within the current app
    
    private func bind() {
        localStorageProvider.incoming.sink { result in
            let selection = self.selection
            guard selection.available == .yes else { return }
//            Task {
//                do {
//                    switch result {
//                    case .success(let paths):
//                        try await selection.provider.send(content: .file(paths))
//                    case .failure(let error):
//                        print(error)
//                        break
//                    }
//                    
//                } catch {
//                    print("there is error \(error)")
//                }
//            }
            
            print("try to upload to: \(selection)")
        }
        .store(in: &cancellables)
        
        
        for x in providers {
            let a = x.value.available.sink { a in
                self.availabilities[x.key] = a
            }
        }
        
//        sidecarMonitor.onChange
//            .tryMap({ try String(contentsOf: $0, encoding: .utf8) })
//            .catch { error -> AnyPublisher<String, Never> in
//                ErrorTracker.shared.add(error)
//                return Empty().eraseToAnyPublisher()
//            }
//            .filter { [weak self] event in
//                let appid = self?.Pref.value(for: PieceSaver.Key.appIdentifier) ?? ""
//                return appid == event
//            }
////            .delay(for: .seconds(2), scheduler: RunLoop.main)
//            .sink { x in
//                let selection = self.selection
//                guard selection.available == .yes else { return }
//                Task {
//                    do {
//                        try await selection.provider.send(content: .file(try self.localStorageProvider.getPaths()))
//                    } catch {
//                        print("there is error \(error)")
//                    }
//                }
//            }
//            .store(in: &cancellables)
    }
    
    func save(document html: String) async throws {
        try await localStorageProvider.send(content: .html(html))
    }
    
    func load() throws -> String {
        // TODO: should I refine this????
        let paths = try localStorageProvider.getPaths()
        return try String(contentsOf: paths.document, encoding: .utf8)
    }
    
    enum SomeError: Error, LocalizedError {
        case missingApplicationSupportDirectory
    }
}

extension Synchronizer {
    protocol Provider {
        // Downstream
        var incoming: AnyPublisher<Result<Paths, Error>, Never> { get }
        
        // Upstream
        func send(content: Synchronizer.Content) async throws
        
        var available: AnyPublisher<Availability, Never> { get }
        
        func prepare() async throws
//            func start or prepare?? to start monitor etc, it may throw an
            // monitor file
            // ask user to signin
            // etc
        
        func pause() async throws
        
        func getPaths() throws -> Paths
    }
    
    struct Paths {
        let document: URL
        let sidecar: URL
    }
    
    enum FileName {
        static let document = "nustash_index.html"
        static let sidecar = "nustash_index.html.sidecar"
    }
    
    enum Option: String, CaseIterable, Identifiable {
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
    
    enum Content {
        case file(Paths)
        case html(String)
    }
    
    struct Selection {
        let approach: Option
        let available: Availability
        let provider: Provider
    }
}

extension Synchronizer.Provider {
    func send(content: Synchronizer.Content) async throws {
        switch content {
        case .file(let from):
            let to = try getPaths()
            guard from.document != to.document && from.sidecar != to.sidecar else { return }
            try await FileHelper.replaceFile(from: from.document, to: to.document)
            try await FileHelper.replaceFile(from: from.sidecar, to: to.sidecar)
        case .html(let html):
            let to = try getPaths()
            try html.write(to: to.document, atomically: true, encoding: .utf8)
            let appid = UUID().uuidString
            try appid.write(to: to.sidecar, atomically: true, encoding: .utf8)
        }
    }
}
