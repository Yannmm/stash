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
    final class DropboxProvider: RemoteProvider, Polling {
        
        var readiness: AnyPublisher<Result<any ProviderReadiness, Error>, Never> { _authentication.eraseToReadinessPublisher() }
        
        private let _authentication = CurrentValueSubject<Result<AuthStatus, Error>, Never>(.success(.initializing("Dropbox")))
        
        var strayError: AnyPublisher<(String, Error)?, Never> { _strayError.eraseToAnyPublisher() }
        
        private let _strayError = PassthroughSubject<(String, Error)?, Never>()
        
        var onArrive: AnyPublisher<Sidecar, Never> { _onArrive.eraseToAnyPublisher() }
        
        func setOnArrive(_ sidecar: Sidecar) { _onArrive.send(sidecar) }
        
        private let _onArrive = PassthroughSubject<Sidecar, Never>()
        
        private var _sdkInitialized = false
        
        var polanchor: UUID?
        
        var poltask: Task<Void, Never>?
        
        private var accountName: String?
        
        private var cancellables = Set<AnyCancellable>()
        
        // MARK: - Protocol
        
        func prepare() async throws {
            observe(true)
            guard !_sdkInitialized else { return }
            _sdkInitialized = true
            DropboxClientsManager.setupWithAppKeyDesktop("y6ijm2p3vqr7kt8")
            await checkAuth()
        }
        
        func pause() async throws {
            observe(false)
        }
        
        func sidecar() async throws -> Sidecar {
            let data = try await download(path: Constant.sidecarPath)
            return try JSONDecoder().decode(Sidecar.self, from: data)
        }
        
        func document() async throws -> Data {
            return try await download(path: Constant.documentPath)
        }
        
        func send(document: Data, sidecar: Sidecar) async throws {
            // Upload document
            try await upload(path: Constant.documentPath, data: document)
            // Upload sidecar and update cached hash
            try await upload(path: Constant.sidecarPath, data: try JSONEncoder().encode(sidecar))
            polanchor = sidecar.uid
        }
        
        func onPollError(_ error: Error) {
            _strayError.send(("dropbox poll", error))
        }
        
        // MARK: - Helpers
        
        private func checkAuth() async {
            do {
                if let client = DropboxClientsManager.authorizedClient {
                    let name = try await _getAccount(client)
                    _authentication.send(.success(AuthStatus.ready(name, { [weak self] _ in self?.logout() })))
                    startpol()
                } else {
                    _authentication.send(.success(AuthStatus.anonymous({ [weak self] _ in self?.authenticate() })))
                }
            } catch {
                _authentication.send(.failure(error))
            }
        }
        
        private func observe(_ flag: Bool) {
            cancellables.forEach({ $0.cancel() })
            cancellables.removeAll()
            if flag {
                // Observe
                NotificationCenter.default.publisher(for: .onUrlEvent)
                    .compactMap { $0.object as? URL }
                    .filter { $0.scheme?.starts(with: "db-") == true }
                    .sink { [weak self] url in
                        self?.handleAuth(url)
                    }
                    .store(in: &cancellables)
                
                NetworkMonitor.shared.onChange.sink { [weak self] in
                    Task {
                        await self?.checkAuth()
                    }
                }
                .store(in: &cancellables)
            }
        }
        
        private func download(path: String) async throws -> Data {
            guard let client = DropboxClientsManager.authorizedClient else {
                throw SyncError.unauthenticated
            }
            
            return try await withCheckedThrowingContinuation { continuation in
                let request = client.files.download(path: path)
                request.response { [weak self] response, error in
                    _ = request
                    if let response {
                        continuation.resume(returning: response.1)
                    } else if let error,
                              let someError = self?.handleError(error, path: path, isFileNotFound: { error in
                                  if case .path(let lookupError) = error,
                                     case .notFound = lookupError {
                                      return true
                                  } else {
                                      return false
                                  }
                              }) {
                        continuation.resume(throwing: someError)
                    } else {
                        continuation.resume(throwing: SyncError.unexpected("Something unexpected happended while downloading file at \"\(path)\"."))
                    }
                }
            }
        }
        
        @discardableResult
        private func upload(path: String, data: Data) async throws -> Files.FileMetadata {
            guard let client = DropboxClientsManager.authorizedClient else {
                throw SyncError.unauthenticated
            }
            
            return try await withCheckedThrowingContinuation { continuation in
                let request = client.files.upload(path: path, mode: .overwrite, input: data)
                request.response { [weak self] metadata, error in
                    _ = request
                    if let metadata {
                        continuation.resume(returning: metadata)
                    } else if let error,
                              let someError = self?.handleError(error, path: path, isFileNotFound: nil) {
                        continuation.resume(throwing: someError)
                    } else {
                        continuation.resume(throwing: SyncError.unexpected("Something unexpected happended while uploading file to \"\(path)\"."))
                    }
                }
            }
        }
        
        private func _getAccount(_ client: DropboxClient) async throws -> String {
            if let name = accountName {
                return name
            }
            let result = try await withCheckedThrowingContinuation { continuation in
                let request = client.users.getCurrentAccount()
                request.response { [weak self, request] account, error in
                    _ = request // Keep the request alive until its response arrives.
                    if let account {
                        continuation.resume(returning: account.name.displayName)
                    } else if let error, let someError = self?.handleError(
                        error,
                        path: nil,
                        isFileNotFound: nil
                    ) {
                        continuation.resume(throwing: someError)
                    } else {
                        continuation.resume(throwing: SyncError.unexpected("Something unexpected happened while getting Dropbox user account."))
                    }
                }
            }
            
            accountName = result
            
            return result
        }
        
        private func handleError<T>(
            _ error: CallError<T>,
            path: String?,
            isFileNotFound: ((T) -> Bool)?
        ) -> SyncError {
            let someError: SyncError
            
            switch error {
            case .authError, .accessError:
                someError = .tokenExpired
                
            case .clientError(let ce):
                if case .oauthError = ce {
                    someError = .tokenExpired
                } else {
                    someError = .api(error)
                }
                
            case .routeError(let boxed, _, _, _):
                if isFileNotFound?(boxed.unboxed) ?? false, let p = path {
                    someError = .fileNotFound(p)
                } else {
                    fallthrough
                }
            default:
                someError = .api(error)
            }
            return someError
        }
        
        private func authenticate() {
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
        
        private func logout() {
            accountName = nil
            DropboxClientsManager.unlinkClients()
            pausepol()
            Task {
                await checkAuth()
            }
        }
        
        private func handleAuth(_ url: URL) {
            let oauthCompletion: DropboxOAuthCompletion = { [weak self] in
                if let authResult = $0 {
                    switch authResult {
                    case .success:
                        Task {
                            await self?.checkAuth()
                        }
                    case .cancel:
                        self?._authentication.send(.success(.anonymous({ _ in self?.authenticate() })))
                    case .error(let error, _):
                        self?._authentication.send(.failure(error))
                    }
                }
            }
            let flag = DropboxClientsManager.handleRedirectURL(url, includeBackgroundClient: false, completion: oauthCompletion)
            guard flag else { return }
            NSApp.activate(ignoringOtherApps: true)
        }
        
        deinit {
            pausepol()
        }
    }
}
