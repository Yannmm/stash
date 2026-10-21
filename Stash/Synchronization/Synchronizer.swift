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
        
    private let _readiness = PassthroughSubject<Result<ProviderReadiness, Error>?, Never>()
    
    private let _error = CurrentValueSubject<(String, Error)?, Never>(nil)
    
    var description: AnyPublisher<AttributedString?, Never> { _description.eraseToAnyPublisher() }
    
    private let _description = PassthroughSubject<AttributedString?, Never>()
    
    var onChange: AnyPublisher<Void, Never> { _onChange.eraseToAnyPublisher() }
    
    private let _onChange = PassthroughSubject<Void, Never>()
    
    private var cancellables = Set<AnyCancellable>()
    
    private let providers: [Option: any Provider]
    
    private let remoteProviders: [Option: any RemoteProvider]
    
    private let local: LocalProvider
    
    private let history = History()
    
    private var remote: (any RemoteProvider)? {
        let a = _approach.value
        return providers[a] as? (any RemoteProvider)
    }
    
    init(approach: Option, remoteProviders: [Option: any RemoteProvider], localProvider: LocalProvider) {
        self._approach = CurrentValueSubject<Option, Never>(approach)
        self.remoteProviders = remoteProviders
        self.providers = remoteProviders.mapValues { $0 as any Provider }
            .merging([Option.local: localProvider].mapValues { $0 as any Provider },
                     uniquingKeysWith: { _, new in new })
        self.local = localProvider
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
//                    这里要 handle
                }
            }
            .store(in: &cancellables)
        
        _approach
            .map { key -> AnyPublisher<Result<any ProviderReadiness, Error>?, Never> in
                guard let readiness = self.remoteProviders[key]?.readiness else {
                    return Just<Result<any ProviderReadiness, Error>?>(nil).eraseToAnyPublisher()
                }
                return readiness
                    .map { Optional($0) }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { x in
                self._readiness.send(x)
            }
            .store(in: &cancellables)
        
        _readiness
            .filter { result in
                guard let r = result else { return false }
                switch r {
                case .success(let r):
                    return r.ready
                case .failure(_):
                    return false
                }
            }
            .sink { [weak self] result in
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
        
        
        _approach
            .compactMap { [weak self] in self?.remoteProviders[$0]?.onArrive }
            .switchToLatest()
            .sink { [weak self] remoteSidecar in
                Task { await self?.handleRemoteIncoming(remoteSidecar) }
            }
            .store(in: &cancellables)
        
        _approach
            .removeDuplicates()
            .sink { [weak self] _ in
                self?._error.send(nil)
            }
            .store(in: &cancellables)
        
        Publishers.CombineLatest(_readiness, _error)
            .map { t2 in
                var attr = AttributedString()
                if let result = t2.0 {
                    switch result {
                    case .success(let status):
                        attr += status.describe()
                    case .failure(let error):
                        attr += AttributedString(error.localizedDescription)
                    }
                }
                
                if let error = t2.1 {
                    attr += AttributedString("\n")
                    attr += AttributedString(error.0) + AttributedString(error.1.localizedDescription)
                }
                if attr.characters.count > 0 {
                    return attr
                } else {
                    return nil
                }
            }
            .sink { [weak self] attr in
                self?._description.send(attr)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public API
    
    func save(document html: String) {
        Task {
            do {
                let sidecar = try local.write(html: html)
                history.log(action: "local_edit", sidecar: sidecar)
                guard let r = remote else {
                    history.log(action: "[save] remote not available do nothing", sidecar: sidecar)
                    return
                }
                guard let document = try await _localDocument() else {
                    throw SyncError.fileNotFound(FileName.document)
                }
                try await r.send(document: document, sidecar: sidecar)
                history.log(action: "push_to_\(_approach.value.rawValue)", sidecar: sidecar)
            } catch {
                _error.send((#function, error))
            }
        }
    }
    
    func load() async -> String? {
        do {
            guard let document = try await _localDocument() else {
                return nil
            }
            guard let html = String(data: document, encoding: .utf8) else {
                throw SyncError.corruptData(document)
            }
            return html
        } catch {
            _error.send((#function, error))
            return nil
        }
    }
    
    func compare() async {
        func _push(to remote: RemoteProvider, sidecar: Sidecar, document: Data?) async throws {
            guard let d = document, d.count > 0 else {
                history.log(action: "skip push_to_\(_approach.value.rawValue) for empty document", sidecar: sidecar)
                return
            }
            try await remote.send(document: d, sidecar: sidecar)
            history.log(action: "push_to_\(_approach.value.rawValue)", sidecar: sidecar)
        }
        
        func _pull(to local: LocalProvider, sidecar: Sidecar, document: Data?) async throws {
            guard let d = document, d.count > 0 else {
                history.log(action: "empty document download_from_\(_approach.value.rawValue) ", sidecar: sidecar)
                return
            }
            try await local.copy(document: d, sidecar: sidecar)
            history.log(action: "download_from_\(_approach.value.rawValue)", sidecar: sidecar)
        }
        
        guard let remote = remote else { return }
        do {
            let sidecar1 = try await _localSidecar()
            let sidecar2 = try await _remoteSidecar(remote)
            
            if let sidecar1 = sidecar1, let sidecar2 = sidecar2 {
                if sidecar2.timestamp > sidecar1.timestamp {
                    try await _pull(to: local, sidecar: sidecar2, document: try await _remoteDocument(remote))
                } else if sidecar1.timestamp > sidecar2.timestamp {
                    try await _push(to: remote, sidecar: sidecar1, document: try await _localDocument())
                } else {
                    // sidecar equal
                }
            } else if let sidecar1 = sidecar1 {
                try await _push(to: remote, sidecar: sidecar1, document: try await _localDocument())
            } else if let sidecar2 = sidecar2 {
                await handleRemoteIncoming(sidecar2)
            } else { // both nil
                // do nothing
            }
        } catch {
            _error.send((#function, error))
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
                try await local.copy(document: document, sidecar: remoteSidecar)
                history.log(action: "download_from_\(_approach.value.rawValue)", sidecar: remoteSidecar)
            } else {
                throw SyncError.fileNotFound(FileName.document)
            }
        } catch {
            _error.send((#function, error))
        }
    }
    
    private func _localSidecar() async throws -> Sidecar? {
        do {
            return try await local.sidecar()
        } catch SyncError.fileNotFound {
            return nil
        } catch {
            throw error
        }
    }
    
    private func _localDocument() async throws -> Data? {
        do {
            return try await local.document()
        } catch SyncError.fileNotFound {
            return nil
        } catch {
            throw error
        }
    }
    
    private func _remoteSidecar(_ remote: Provider) async throws -> Sidecar? {
        do {
            return try await remote.sidecar()
        } catch SyncError.fileNotFound {
            return nil
        } catch {
            throw error
        }
    }
    
    private func _remoteDocument(_ remote: Provider) async throws -> Data? {
        do {
            return try await remote.document()
        } catch SyncError.fileNotFound {
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
}
