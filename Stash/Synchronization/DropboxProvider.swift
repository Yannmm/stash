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

extension Synchronizer {
    final class DropboxProvider: OAuthProvider {
        
        private var _sdkInitialized = false
        
        init() {
            super.init(name: "Dropbox", directory: "")
        }
        
        // MARK: - Overrides
        
        override var isAuthorized: Bool { DropboxClientsManager.authorizedClient != nil }
        
        override func prepare() async throws {
            if !_sdkInitialized {
                _sdkInitialized = true
                DropboxClientsManager.setupWithAppKeyDesktop("y6ijm2p3vqr7kt8")
            }
            try await super.prepare()
        }
        
        override func isRedirect(_ url: URL) -> Bool {
            url.scheme?.starts(with: "db-") == true
        }
        
        override func download(path: String) async throws -> Data {
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
        
        override func upload(path: String, data: Data) async throws {
            guard let client = DropboxClientsManager.authorizedClient else {
                throw SyncError.unauthenticated
            }
            
            let _: Files.FileMetadata = try await withCheckedThrowingContinuation { continuation in
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
        
        override func fetchAccountName() async throws -> String? {
            guard let client = DropboxClientsManager.authorizedClient else {
                throw SyncError.unauthenticated
            }
            return try await withCheckedThrowingContinuation { continuation in
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
        
        override func authenticate() {
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
        
        override func unlink() {
            DropboxClientsManager.unlinkClients()
        }
        
        override func handleRedirect(_ url: URL) {
            let oauthCompletion: DropboxOAuthCompletion = { [weak self] in
                if let authResult = $0 {
                    switch authResult {
                    case .success:
                        Task {
                            await self?.checkAuth()
                        }
                    case .cancel:
                        self?.signedOut()
                    case .error(let error, _):
                        self?.authFailed(error)
                    }
                }
            }
            let flag = DropboxClientsManager.handleRedirectURL(url, includeBackgroundClient: false, completion: oauthCompletion)
            guard flag else { return }
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
