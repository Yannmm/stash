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
    
    private let lane = Lane()
    
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
                    do {
                        try await oldProvider?.pause()
                        try await newProvider?.prepare()
                    } catch {
                        self?._error.send(("rotate provider from \(old?.rawValue ?? "N/A") to \(new.rawValue)", error))
                    }
                }
            }
            .store(in: &cancellables)
        
        _approach
            .map { self.remoteProviders[$0] }
            .map { p in
                guard let readiness = p?.readiness else {
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
        
        _approach
            .map { self.remoteProviders[$0] }
            .map({ p in
                guard let error = p?.strayError else {
                    return Just<(String, Error)?>(nil).eraseToAnyPublisher()
                }
                return error
            })
            .switchToLatest()
            .sink { x in
                self._error.send(x)
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
            .sink { [weak self] _ in
                guard let self, let r = self.remote else { return }
                self.lane.enqueue {
                    do {
                        await self.reconcile(provider: r, remote: try await self._remoteSidecar(r))
                    } catch {
                        self._error.send(("compare", error))
                    }
                }
            }
            .store(in: &cancellables)
        
        local.onArrive
            .sink { [weak self] _ in
                self?._onChange.send(())
            }
            .store(in: &cancellables)
        
        
        _approach
            .map { [weak self] option -> AnyPublisher<(any RemoteProvider, Sidecar?), Never> in
                guard let p = self?.remoteProviders[option] else {
                    return Empty().eraseToAnyPublisher()
                }
                return p.onArrive.map { (p, $0) }.eraseToAnyPublisher()
            }
            .switchToLatest()
            .sink { [weak self] provider, remoteSidecar in
                guard let self else { return }
                // Drop ticks while a reconcile is pending, the next tick retries
                self.lane.enqueue(droppable: true) {
                    await self.reconcile(provider: provider, remote: remoteSidecar)
                }
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
        lane.enqueue { [self] in
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
    
    // MARK: - Private
    
    /// Reconciles local with `remoteSidecar` of `provider` by timestamp, last writer wins.
    private func reconcile(provider: any RemoteProvider, remote remoteSidecar: Sidecar?) async {
        let name = _approach.value.rawValue
        
        func _push(sidecar: Sidecar) async throws {
            guard let d = try await _localDocument(), d.count > 0 else {
                history.log(action: "skip push_to_\(name) for empty document", sidecar: sidecar)
                return
            }
            try await provider.send(document: d, sidecar: sidecar)
            history.log(action: "push_to_\(name)", sidecar: sidecar)
        }
        
        func _pull(sidecar: Sidecar) async throws {
            guard let d = try await _remoteDocument(provider) else {
                throw SyncError.fileNotFound(FileName.document)
            }
            guard d.count > 0 else {
                history.log(action: "skip download_from_\(name) for empty document", sidecar: sidecar)
                return
            }
            try await local.copy(document: d, sidecar: sidecar)
            history.log(action: "download_from_\(name)", sidecar: sidecar)
        }
        
        do {
            let localSidecar = try await _localSidecar()
            switch (localSidecar, remoteSidecar) {
            case (nil, nil):
                break
            case (let l?, nil):
                try await _push(sidecar: l)
            case (nil, let r?):
                try await _pull(sidecar: r)
            case (let l?, let r?):
                if l.uid == r.uid {
                    break
                } else if l.timestamp > r.timestamp {
                    try await _push(sidecar: l)
                } else {
                    try await _pull(sidecar: r)
                }
            }
        } catch {
            _error.send(("reconcile", error))
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
