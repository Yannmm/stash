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
            guard approach != oldValue else { return }
            let oldProvider = providers[oldValue]
            let newProvider = remoteProvider
            Task {
                try? await oldProvider?.pause()
                try? await newProvider?.prepare()
                await align()
            }
        }
    }

    let onChange: AnyPublisher<Void, Never>
    private let _onChange = PassthroughSubject<Void, Never>()

    private var cancellables = Set<AnyCancellable>()
    private let providers: [Option: any Provider]
    private let localProvider: LocalStorageProvider
    private let history = History()

    private var remoteProvider: (any Provider)? {
        guard approach != .local else { return nil }
        return providers[approach]
    }

    init(approach: Option, providers: [Option: any Provider], localProvider: LocalStorageProvider) {
        self.approach = approach
        self.providers = providers
        self.localProvider = localProvider
        self.onChange = _onChange.eraseToAnyPublisher() 
        bind()
    }

    private func bind() {
        localProvider.onArrive
            .sink { [weak self] _ in
                self?._onChange.send(())
            }
            .store(in: &cancellables)

        for (option, provider) in providers where option != .local {
            provider.onArrive
                .sink { [weak self] remoteSidecar in
                    guard let self, self.approach == option else { return }
                    Task { await self.handleRemoteIncoming(remoteSidecar) }
                }
                .store(in: &cancellables)
        }
    }

    // MARK: - Public API

    func save(document html: String) {
        do {
            let sidecar = try localProvider.write(html: html)
            history.log(action: "local_edit", sidecar: sidecar)
            guard let remote = remoteProvider else { return }
            Task {
                do {
                    let document = try await localProvider.document()
                    try await remote.send(document: document, sidecar: sidecar)
                    history.log(action: "push_to_\(approach.rawValue)", sidecar: sidecar)
                } catch {
                    print("[Sync] push failed: \(error)")
                }
            }
        } catch {
            print("[Sync] local write failed: \(error)")
        }
    }

    func load() async throws -> String {
        let data = try await localProvider.document()
        guard let html = String(data: data, encoding: .utf8) else {
            throw SyncError.corruptDocument
        }
        return html
    }

    func align() async {
        guard let remote = remoteProvider else { return }
        do {
            let availability = await remote.checkAvailability()
            guard availability == .yes else { return }

            let sidecar1 = try await remote.sidecar()
            let sidecar2 = try await localProvider.sidecar()

            if sidecar1.timestamp > sidecar2.timestamp {
                let document = try await remote.document()
                try await localProvider.send(document: document, sidecar: sidecar1)
                history.log(action: "download_from_\(approach.rawValue)", sidecar: sidecar1)
            } else if sidecar2.timestamp > sidecar1.timestamp {
                let document = try await localProvider.document()
                try await remote.send(document: document, sidecar: sidecar2)
                history.log(action: "push_to_\(approach.rawValue)", sidecar: sidecar2)
            }
        } catch {
            print("[Align] align failed: \(error)")
        }
    }

    // MARK: - Private

    private func handleRemoteIncoming(_ remoteSidecar: Sidecar) async {
        do {
            let localSidecar = try await localProvider.sidecar()
            guard remoteSidecar.uid != localSidecar.uid else { return }
            guard remoteSidecar.timestamp > localSidecar.timestamp else { return }

            guard let remote = remoteProvider else { return }
            let document = try await remote.document()
            try await localProvider.send(document: document, sidecar: remoteSidecar)
            history.log(action: "download_from_\(approach.rawValue)", sidecar: remoteSidecar)
        } catch {
            print("[Sync] remote incoming failed: \(error)")
        }
    }
}

// MARK: - Protocol & Types

extension Synchronizer {
    enum FileName {
        static let document = "nustash_index.html"
        static let sidecar = "nustash_index.html.sidecar"
    }

    protocol Provider {
        var onArrive: AnyPublisher<Sidecar, Never> { get }
        func sidecar() async throws -> Sidecar
        func document() async throws -> Data
        func send(document: Data, sidecar: Sidecar) async throws
        func checkAvailability() async -> Availability
        func prepare() async throws
        func pause() async throws
    }

    enum Option: String, CaseIterable, Identifiable {
        var id: String { rawValue }
        case icloud
        case local
        case dropbox
    }

    enum Availability: Equatable {
        static func == (lhs: Availability, rhs: Availability) -> Bool {
            switch (lhs, rhs) {
            case (.yes, .yes): return true
            case (.no, .no): return true
            default: return false
            }
        }
        case yes
        case no(Error?)
    }

    enum SyncError: Error, LocalizedError {
        case corruptDocument
        case corruptSidecar
    }
}

extension Synchronizer.Provider {
    func prepare() async throws {}
    func pause() async throws {}
}
