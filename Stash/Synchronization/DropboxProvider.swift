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
            NotificationCenter.default.publisher(for: .oauthCallback)
                .compactMap { $0.object as? URL }
                .filter { $0.scheme?.starts(with: "db-") == true }
                .sink { [weak self] url in
                    self?.handleRedirectURL(url)
                }
                .store(in: &cancellables)
        }
        
        // MARK: - Protocol
        func checkAvailability() async {
            var a: Availability!
            if signedIn {
                let name = await getAccount()
                a = .yes(AuthStatus.ready(name, logout))
                startpol()
            } else {
                a = .no(AuthStatus.anonymous({ [weak self] in
                    self?.authenticate()
                }))
            }
            _availability.send(a)
        }
        
        func sidecar() async throws -> Sidecar? {
            guard let client = DropboxClientsManager.authorizedClient else {
                _availability.send(.no(AuthStatus.anonymous(authenticate)))
                return nil
            }
            do {
                let data = try await download(client: client, path: Constant.sidecarPath)
                return try JSONDecoder().decode(Sidecar.self, from: data)
            } catch SomeError.fileNotFound {
                return nil
            }
        }
        
        func document() async throws -> Data? {
            guard let client = DropboxClientsManager.authorizedClient else {
                _availability.send(.no(AuthStatus.anonymous(authenticate)))
                return nil
            }
            do {
                return try await download(client: client, path: Constant.documentPath)
            } catch SomeError.fileNotFound {
                return nil
            }
        }
        
        func send(document: Data, sidecar: Sidecar) async throws {
            guard let client = DropboxClientsManager.authorizedClient else {
                _availability.send(.no(AuthStatus.anonymous(authenticate)))
                return
            }
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
                            continuation.resume(with: .failure(SomeError.api(error.description)))
                        }
                    } else {
                        continuation.resume(with: .failure(SomeError.api("Unknown download error")))
                    }
                }
            }
        }
        
        @discardableResult
        private func upload(client: DropboxClient, path: String, data: Data) async throws -> Files.FileMetadata {
            try await withCheckedThrowingContinuation { continuation in
                client.files.upload(path: path, mode: .overwrite, input: data).response { metadata, error in
                    if let metadata {
                        continuation.resume(returning: metadata)
                    } else if let error {
                        continuation.resume(with: .failure(SomeError.api(error.description)))
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
                            self?._availability.send(.yes(AuthStatus.ready(name, this.logout)))
                        }
                    case .cancel:
                        self?._availability.send(.no(AuthStatus.anonymous({ [weak self] in
                            self?.authenticate()
                        })))
                    case .error(let error, _):
                        self?._availability.send(.no(AuthStatus.error(error, { [weak self] in
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
        case fileNotFound(String)
        case api(String)
    }
}

extension Synchronizer.DropboxProvider {
    enum AuthStatus {
        case anonymous(() -> Void)
        case ready(String?, () -> Void)
        case error(Error, () -> Void)
    }
}

extension Synchronizer.DropboxProvider.AuthStatus: Synchronizer.Descriptor {
    func describe() -> AttributedString {
        switch self {
        case .anonymous:
            var attr = AttributedString("Please sign in Dropbox.")
            attr.foregroundColor = .secondary
            if let range = attr.range(of: "sign in") {
                attr[range].foregroundColor = Color.theme
                attr[range].link = URL(string: "action://abc")
            }
            return attr
        case .error(let e, _):
            var attr = AttributedString("An error happended, please try again: \(e.localizedDescription)")
            attr.foregroundColor = .secondary
            if let range = attr.range(of: "try again") {
                attr[range].foregroundColor = Color.theme
                attr[range].link = URL(string: "action://abc")
            }
            return attr
        case .ready(let name, _):
            var attr = AttributedString("Already signed in Dropbox")
            if let n = name {
                attr = attr + AttributedString(" as \(n)")
            }
            attr = attr + AttributedString(" (logout)")
            attr.foregroundColor = .secondary
            if let n = name, let range = attr.range(of: n) {
                attr[range].foregroundColor = Color.theme
            }
            if let range = attr.range(of: "logout") {
                attr[range].foregroundColor = Color.red
                attr[range].link = URL(string: "action://abc")
            }
            
            return attr
        }
    }
    
    func action(_ phrase: String) {
        switch self {
        case .anonymous(let action):
            action()
        case .error(_, let action):
            action()
        case .ready(_, let action):
            action()
        }
    }
}
