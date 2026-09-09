//
//  Synchronizer.swift
//  Stash
//
//  Created by Rayman on 2026/5/11.
//

import Foundation
import Combine

class Synchronizer {
    let _approach: CurrentValueSubject<Option, Never>!
    
    var approach: AnyPublisher<Option, Never> { _approach.eraseToAnyPublisher() }
    
    func setApproach(_ value: Option) {
        _approach.send(value)
    }
    
    private(set) var availability: AnyPublisher<Availability, Never>!
    
    let onChange: AnyPublisher<Void, Never>
    
    private let _onChange = PassthroughSubject<Void, Never>()
    
    private var cancellables = Set<AnyCancellable>()
    
    private let providers: [Option: any Provider]
    
    private let local: OnPremiseProvider
    
    private let history = History()
    
    private var remote: (any Provider)? {
        let a = _approach.value
        guard a != .local else { return nil }
        return providers[a]
    }
    
    init(approach: Option, providers: [Option: any Provider], localProvider: OnPremiseProvider) {
        self._approach = CurrentValueSubject<Option, Never>(approach)
        self.providers = providers
        self.local = localProvider
        self.onChange = _onChange.eraseToAnyPublisher()
        bind()
    }
    
    private func bind() {
        self._approach
            .removeDuplicates()
            .scan((Option?.none, Option?.none)) { pair, value in
                (pair.1, value)
            }
            .compactMap { pair in
                pair.1.map { (pair.0, $0) }
            }
            .sink { [weak self]  x  in
                let old = x.0
                let new = x.1
                let oldProvider = old != nil ? self?.providers[old!] : nil
                let newProvider = self?.providers[new]
                Task {
                    try? await oldProvider?.pause()
                    try? await newProvider?.prepare()
                }
            }.store(in: &cancellables)
        
        self.availability = _approach
            .compactMap { self.providers[$0]?.availability }
            .switchToLatest()
            .eraseToAnyPublisher()
        
        self.availability
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .filter {
                guard case .yes = $0 else {
                    return false
                }
                return true
            }
            .sink { [weak self] _ in
                Task {
                    await self?.compare()
                }
            }
            .store(in: &cancellables)
        
        
        local.onArrive
            .sink { [weak self] _ in
                self?._onChange.send(())
            }
            .store(in: &cancellables)
        
        for (option, provider) in providers where option != .local {
            provider.onArrive
                .sink { [weak self] remoteSidecar in
                    guard let self, self._approach.value == option else { return }
                    Task { await self.handleRemoteIncoming(remoteSidecar) }
                }
                .store(in: &cancellables)
        }
    }
    
    // MARK: - Public API
    
    func save(document html: String) {
        do {
            let sidecar = try local.write(html: html)
            history.log(action: "local_edit", sidecar: sidecar)
            guard let r = remote else {
                print("[save] remote not available do nothing")
                return
            }
            Task {
                do {
                    guard let document = try await _localDocument() else {
                        throw SomeError.fileNotFound(FileName.document)
                    }
                    try await r.send(document: document, sidecar: sidecar)
                    history.log(action: "push_to_\(_approach.value.rawValue)", sidecar: sidecar)
                } catch {
                    print("[Sync] push failed: \(error)")
                    ErrorTracker.shared.add(error)
                }
            }
        } catch {
            print("[Sync] local write failed: \(error)")
            ErrorTracker.shared.add(error)
        }
    }
    
    func load() async throws -> String? {
        do {
            guard let document = try await _localDocument() else {
                return nil
            }
            guard let html = String(data: document, encoding: .utf8) else {
                throw SomeError.corruptDocument
            }
            return html
        } catch SomeError.fileNotFound {
            return nil
        } catch {
            throw error
        }
    }
    
    func compare() async {
        func _push(to remote: Provider, sidecar: Sidecar, document: Data?) async throws {
            guard let d = document, d.count > 0 else { return }
            try await remote.send(document: d, sidecar: sidecar)
            history.log(action: "push_to_\(_approach.value.rawValue)", sidecar: sidecar)
        }
        
        func _pull(to local: Provider, sidecar: Sidecar, document: Data?) async throws {
            guard let d = document, d.count > 0 else { return }
            try await local.send(document: d, sidecar: sidecar)
            history.log(action: "download_from_\(_approach.value.rawValue)", sidecar: sidecar)
        }
        
        guard let remote = remote else { return }
        do {
            let availability = await remote.getAvailability()
            guard case .yes = availability else {
                print("[Align] remote provider not available, do nothing")
                return
            }
            
            let sidecar1 = try await _localSidecar()
            let sidecar2 = try await _remoteSidecar(remote)
            
            if let sidecar1 = sidecar1, let sidecar2 = sidecar2 {
                if sidecar2.timestamp > sidecar1.timestamp {
                    try await _pull(to: local, sidecar: sidecar2, document: try await _remoteDocument(remote))
                } else if sidecar1.timestamp > sidecar2.timestamp {
                    try await _push(to: remote, sidecar: sidecar1, document: try await _localDocument())
                } else {
                    print("[Align] sidecar equal, dothing")
                }
            } else if let sidecar1 = sidecar1 {
                try await _push(to: remote, sidecar: sidecar1, document: try await _localDocument())
            } else if let sidecar2 = sidecar2 {
                await handleRemoteIncoming(sidecar2)
            } else { // both nil
                // do nothing
            }
        } catch {
            print("[Align] align failed: \(error)")
            ErrorTracker.shared.add(error)
        }
    }
    
    // MARK: - Private
    
    private func handleRemoteIncoming(_ remoteSidecar: Sidecar) async {
        do {
            if let sidecar1 = try await _localSidecar() {
                guard remoteSidecar.uid != sidecar1.uid else { return }
                guard remoteSidecar.timestamp > sidecar1.timestamp else { return }
            }
            
            guard let remote = remote else { return }
            if let document = try await _remoteDocument(remote) {
                try await local.send(document: document, sidecar: remoteSidecar)
                history.log(action: "download_from_\(_approach.value.rawValue)", sidecar: remoteSidecar)
            } else {
                throw SomeError.fileNotFound(FileName.document)
            }
        } catch {
            print("[Sync] remote incoming failed: \(error)")
            ErrorTracker.shared.add(error)
        }
    }
    
    private func _localSidecar() async throws -> Sidecar? {
        do {
            return try await local.sidecar()
        } catch Synchronizer.OnPremiseProvider.SomeError.fileNotFound {
            return nil
        } catch {
            throw error
        }
    }
    
    private func _localDocument() async throws -> Data? {
        do {
            return try await local.document()
        } catch Synchronizer.OnPremiseProvider.SomeError.fileNotFound {
            return nil
        } catch {
            throw error
        }
    }
    
    private func _remoteSidecar(_ remote: Provider) async throws -> Sidecar? {
        do {
            return try await remote.sidecar()
        } catch Synchronizer.DropboxProvider.SomeError.fileNotFound {
            return nil
        } catch Synchronizer.BaiduPanProvider.SomeError.fileNotFound {
            return nil
        } catch {
            throw error
        }
    }
    
    private func _remoteDocument(_ remote: Provider) async throws -> Data? {
        do {
            return try await remote.document()
        } catch Synchronizer.DropboxProvider.SomeError.fileNotFound {
            return nil
        } catch Synchronizer.BaiduPanProvider.SomeError.fileNotFound {
            return nil
        } catch {
            throw error
        }
    }
}

// MARK: - Protocol & Types

extension Synchronizer {
    enum FileName {
        static let document = "nustash_index.html"
        static let sidecar = "nustash_index.html.sidecar.json"
    }

    enum Option: String, CaseIterable, Identifiable {
        var id: String { rawValue }
        case local
        case icloud
        case dropbox
        case baidupan
    }

    enum SomeError: Error, LocalizedError {
        case corruptDocument
        case corruptSidecar
        case fileNotFound(String)
    }
}
