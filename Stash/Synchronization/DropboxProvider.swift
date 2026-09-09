//
//  DropboxProvider.swift
//  Stash
//
//  Created by Yan Meng on 2026/5/10.
//

import Foundation
import Combine
import SwiftyDropbox
import AppKit
import SwiftUI

fileprivate extension Synchronizer.DropboxProvider {
    enum Constant {
        static let sidecarPath = "/\(Synchronizer.FileName.sidecar)"
        static let documentPath = "/\(Synchronizer.FileName.document)"
    }
}

extension Synchronizer {
    final class DropboxProvider: Provider, Polling {
        private let _onArrive = PassthroughSubject<Sidecar, Never>()
        
        var onArrive: AnyPublisher<Sidecar, Never> { _onArrive.eraseToAnyPublisher() }
        
        func setOnArrive(_ sidecar: Sidecar) { _onArrive.send(sidecar) }
        
        private var cancellables = Set<AnyCancellable>()
        
        var availability: AnyPublisher<Availability, Never> { _availability.eraseToAnyPublisher() }
        
        private let _availability = CurrentValueSubject<Availability, Never>(.no(InitialPendingState(name: "Dropbox")))
        
        private var _sdkInitialized = false
        
        var polanchor: UUID?
        
        var poltask: Task<Void, Never>?
        
        init() {
            NotificationCenter.default.publisher(for: .onUrlEvent)
                .compactMap { $0.object as? URL }
                .filter { $0.scheme?.starts(with: "db-") == true }
                .sink { [weak self] url in
                    self?.handleRedirectURL(url)
                }
                .store(in: &cancellables)
        }
        
        // MARK: - Protocol
        private func checkAvailability() async {
            var a: Availability!
            if signedIn {
                let name = await getAccount()
                a = .yes(AuthStatus.ready(name, { [weak self] _ in self?.logout() }))
                startpol()
            } else {
                a = .no(AuthStatus.anonymous({ [weak self] _ in
                    self?.authenticate()
                }))
            }
            _availability.send(a)
        }
        
        func sidecar() async throws -> Sidecar {
            let data = try await download(client: try getClient(), path: Constant.sidecarPath)
            return try JSONDecoder().decode(Sidecar.self, from: data)
        }
        
        func document() async throws -> Data {
            return try await download(client: try getClient(), path: Constant.documentPath)
        }
        
        func send(document: Data, sidecar: Sidecar) async throws {
            let client = try getClient()
            // Upload document
            try await upload(client: client, path: Constant.documentPath, data: document)
            // Upload sidecar and update cached hash
            try await upload(client: client, path: Constant.sidecarPath, data: try JSONEncoder().encode(sidecar))
            polanchor = sidecar.uid
        }
        
        func prepare() async throws {
            guard !_sdkInitialized else { return }
            _sdkInitialized = true
            DropboxClientsManager.setupWithAppKeyDesktop("y6ijm2p3vqr7kt8")
            await checkAvailability()
        }
        
        private func download(client: DropboxClient, path: String) async throws -> Data {
            try await withCheckedThrowingContinuation { continuation in
                client.files.download(path: path).response { response, error in
                    if let response {
                        continuation.resume(returning: response.1)
                    } else if let error {
                        if case .routeError(let boxed, _, _, _) = error, case .path(let lookupError) = boxed.unboxed, case .notFound = lookupError {
                            continuation.resume(with: .failure(SomeError.fileNotFound(path)))
                        } else {
                            continuation.resume(with: .failure(SomeError.api(error)))
                        }
                    } else {
                        continuation.resume(with: .failure(SomeError.api("Unknown download error")))
                    }
                }
            }
        }
        
        private func getClient() throws -> DropboxClient {
            guard let client = DropboxClientsManager.authorizedClient else {
                _availability.send(.no(AuthStatus.anonymous({ [weak self] _ in self?.authenticate() })))
                throw SomeError.unauthenticated
            }
            return client
        }
        
        @discardableResult
        private func upload(client: DropboxClient, path: String, data: Data) async throws -> Files.FileMetadata {
            try await withCheckedThrowingContinuation { continuation in
                client.files.upload(path: path, mode: .overwrite, input: data).response { metadata, error in
                    if let metadata {
                        continuation.resume(returning: metadata)
                    } else if let error {
                        continuation.resume(with: .failure(SomeError.api(error)))
                    } else {
                        continuation.resume(with: .failure(SomeError.api("Unknown upload error")))
                    }
                }
            }
        }
        
        // MARK: - OAuth
        
        private func handleRedirectURL(_ url: URL) {
            let oauthCompletion: DropboxOAuthCompletion = { [weak self] in
                if let authResult = $0 {
                    switch authResult {
                    case .success:
                        self?.startpol()
                        Task {
                            let name = await self?.getAccount()
                            guard let this = self else { return }
                            self?._availability.send(.yes(AuthStatus.ready(name, { [weak self] _ in self?.logout() })))
                        }
                    case .cancel:
                        self?._availability.send(.no(AuthStatus.anonymous({ [weak self] _ in
                            self?.authenticate()
                        })))
                    case .error(let error, _):
                        self?._availability.send(.no(AuthStatus.error(error, { [weak self] _ in
                            self?.authenticate()
                        })))
                    }
                }
            }
            DropboxClientsManager.handleRedirectURL(url, includeBackgroundClient: false, completion: oauthCompletion)
            NSApp.activate(ignoringOtherApps: true)
        }
        
        // MARK: - Helpers
        
        var signedIn: Bool {
            DropboxClientsManager.authorizedClient != nil
        }
        
        func getAccount() async -> String? {
            guard let client = DropboxClientsManager.authorizedClient else { return nil }
            return await withCheckedContinuation { continuation in
                client.users.getCurrentAccount().response { account, error in
                    if let account {
                        continuation.resume(returning: account.name.displayName)
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
        
        func authenticate() {
            let scope = ScopeRequest(
                scopeType: .user,
                scopes: ["account_info.read", "files.content.read", "files.content.write", "files.metadata.read"],
                includeGrantedScopes: false
            )
            DropboxClientsManager.authorizeFromControllerV2(
                sharedApplication: NSApplication.shared,
                controller: nil,
                loadingStatusDelegate: nil,
                openURL: {(url: URL) -> Void in NSWorkspace.shared.open(url)},
                scopeRequest: scope
            )
        }
        
        func logout() {
            DropboxClientsManager.unlinkClients()
            Task {
                await checkAvailability()
            }
        }
        
        deinit {
            pausepol()
        }
    }
}

extension Synchronizer.DropboxProvider {
    enum SomeError: Error {
        case api(Error)
        case unauthenticated
        case fileNotFound(String)
    }
}
