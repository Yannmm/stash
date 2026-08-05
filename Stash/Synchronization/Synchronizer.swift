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
                    await self?.align()
                }
        }.store(in: &cancellables)
        
        self.availability = _approach
            .compactMap { self.providers[$0]?.availability }
            .switchToLatest()
            .eraseToAnyPublisher()
        
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
                // TODO: do we need to check r.availability??
                print("[save] remote not available do nothing")
                return
            }
            Task {
                do {
                    guard let document = try await local.document() else {
                        throw SyncError.documentNotFound
                    }
                    try await r.send(document: document, sidecar: sidecar)
                    history.log(action: "push_to_\(_approach.value.rawValue)", sidecar: sidecar)
                } catch {
                    print("[Sync] push failed: \(error)")
                }
            }
        } catch {
            print("[Sync] local write failed: \(error)")
        }
    }

    func load() async throws -> String? {
        do {
            guard let data = try await local.document() else {
                return nil
            }
            guard let html = String(data: data, encoding: .utf8) else {
                throw SyncError.corruptDocument
            }
            return html
        } catch SyncError.documentNotFound {
            return nil
        } catch {
            throw error
        }
    }

    func align() async {
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
            let availability = await remote.checkAvailability()
            guard case .yes = availability else {
                print("[Align] remote provider not available, do nothing")
                return
            }
            let sidecar1 = try await local.sidecar()
            let sidecar2 = try await remote.sidecar()
            
            if let sidecar1 = sidecar1, let sidecar2 = sidecar2 {
                if sidecar2.timestamp > sidecar1.timestamp {
                    try await _pull(to: local, sidecar: sidecar2, document: try await remote.document())
                } else if sidecar1.timestamp > sidecar2.timestamp {
                    try await _push(to: remote, sidecar: sidecar1, document: try await local.document())
                } else {
                    print("[Align] sidecar equal, dothing")
                }
            } else if let sidecar1 = sidecar1 {
                try await _push(to: remote, sidecar: sidecar1, document: try await local.document())
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
            if let sidecar1 = try await local.sidecar() {
                guard remoteSidecar.uid != sidecar1.uid else { return }
                guard remoteSidecar.timestamp > sidecar1.timestamp else { return }
            }

            guard let remote = remote else { return }
            if let document = try await remote.document() {
                try await local.send(document: document, sidecar: remoteSidecar)
                history.log(action: "download_from_\(_approach.value.rawValue)", sidecar: remoteSidecar)
            } else {
                throw SyncError.documentNotFound
            }
        } catch {
            print("[Sync] remote incoming failed: \(error)")
        }
    }
}

// MARK: - Protocol & Types

extension Synchronizer {
    enum FileName {
        static let document = "nustash_index.html"
        static let sidecar = "nustash_index.html.sidecar.json"
    }

    protocol Provider {
        var onArrive: AnyPublisher<Sidecar, Never> { get }
        func sidecar() async throws -> Sidecar?
        func document() async throws -> Data?
        func send(document: Data, sidecar: Sidecar) async throws
        @discardableResult func checkAvailability() async -> Availability
        var availability: AnyPublisher<Availability, Never> { get }
        func prepare() async throws
        func pause() async throws
    }

    enum Option: String, CaseIterable, Identifiable {
        var id: String { rawValue }
        case icloud
        case local
        case dropbox
    }

    enum Availability: Equatable, Synchronizer.Descriptor {
        static func == (lhs: Availability, rhs: Availability) -> Bool {
            switch (lhs, rhs) {
            case (.yes, .yes): return true
            case (.no, .no): return true
            case (.pending, .pending): return true
            default: return false
            }
        }
        case yes(Synchronizer.Descriptor)
        case no(Error?)
        case pending(Synchronizer.Descriptor)
    }

    enum SyncError: Error, LocalizedError {
        case corruptDocument
        case corruptSidecar
        case documentNotFound
        case sidecarNotFound
    }
}

extension Synchronizer.Availability {
    func describe() -> AttributedString {
        switch self {
        case .yes(let descriptor):
            return descriptor.describe()
        case .no(let error):
            var attr = AttributedString("\(error?.localizedDescription ?? "no error")")
            return attr
        case .pending(let descriptor):
            return descriptor.describe()
        }
    }
    
    var action: (() -> Void)? {
        switch self {
        case .yes(let name):
            return nil;
        case .no(let error):
            return nil;
        case .pending(let descriptor):
            return descriptor.action
        }
    }
}

extension Synchronizer.Provider {
    func prepare() async throws {
        await checkAvailability()
    }
    func pause() async throws {}
}

extension Synchronizer {
    protocol Descriptor {
        func describe() -> AttributedString
        var action: (() -> Void)? { get }
    }
    
    struct InitialPendingState: Descriptor {
        let name: String
        
        func describe() -> AttributedString {
            var attr = AttributedString("\(name) is initializing.")
            if let range = attr.range(of: name) {
                attr[range].foregroundColor = .primary
            }
            return attr
        }
    }
}

extension Synchronizer.Descriptor {
    var action: (() -> Void)? { nil }
}

extension String: Synchronizer.Descriptor {
    func describe() -> AttributedString { AttributedString(self) }
}
