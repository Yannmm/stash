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
            Task { await sync() }
        }
    }

    let onRemoteDataApplied: AnyPublisher<Void, Never>
    private let _onRemoteDataApplied = PassthroughSubject<Void, Never>()

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
        self.onRemoteDataApplied = _onRemoteDataApplied.eraseToAnyPublisher()
        bind()
    }

    private func bind() {
        localProvider.incoming
            .sink { [weak self] _ in
                self?._onRemoteDataApplied.send(())
            }
            .store(in: &cancellables)

        for (option, provider) in providers where option != .local {
            provider.incoming
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
                    let document = try await localProvider.readDocument()
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

    func load() throws -> String {
        let data = try localProvider.readDocumentSync()
        guard let html = String(data: data, encoding: .utf8) else {
            throw SyncError.corruptDocument
        }
        return html
    }

    func sync() async {
        guard let remote = remoteProvider else { return }
        do {
            let availability = await remote.checkAvailability()
            guard availability == .yes else { return }

            let remoteSidecar = try await remote.readSidecar()
            let localSidecar = try localProvider.readSidecarSync()

            if remoteSidecar.timestamp > localSidecar.timestamp {
                let document = try await remote.readDocument()
                try localProvider.send(document: document, sidecar: remoteSidecar)
                history.log(action: "download_from_\(approach.rawValue)", sidecar: remoteSidecar)
            } else if localSidecar.timestamp > remoteSidecar.timestamp {
                let document = try await localProvider.readDocument()
                try await remote.send(document: document, sidecar: localSidecar)
                history.log(action: "push_to_\(approach.rawValue)", sidecar: localSidecar)
            }
        } catch {
            print("[Sync] sync failed: \(error)")
        }
    }

    // MARK: - Private

    private func handleRemoteIncoming(_ remoteSidecar: SidecarData) async {
        do {
            let localSidecar = try localProvider.readSidecarSync()
            guard remoteSidecar.uid != localSidecar.uid else { return }
            guard remoteSidecar.timestamp > localSidecar.timestamp else { return }

            guard let remote = remoteProvider else { return }
            let document = try await remote.readDocument()
            try localProvider.send(document: document, sidecar: remoteSidecar)
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
        var incoming: AnyPublisher<SidecarData, Never> { get }
        func readSidecar() async throws -> SidecarData
        func readDocument() async throws -> Data
        func send(document: Data, sidecar: SidecarData) async throws
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
