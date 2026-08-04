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

extension Synchronizer {
    final class DropboxProvider: Provider {
        private let _onArrive = PassthroughSubject<Sidecar, Never>()
        var onArrive: AnyPublisher<Sidecar, Never> { _onArrive.eraseToAnyPublisher() }
        
        var availability: AnyPublisher<Availability, Never> { _availability.eraseToAnyPublisher() }
        private let _availability = CurrentValueSubject<Availability, Never>(.pending(InitialPendingState(name: "Dropbox")))
        
        private var _sdkInitialized = false
        private var _lastSidecarHash: String?
        private var pollCancellable: AnyCancellable?
        
        private let sidecarPath = "/\(FileName.sidecar)"
        private let documentPath = "/\(FileName.document)"
        
        init() {}
        
        // MARK: - Protocol
        
        @discardableResult
        func checkAvailability() async -> Availability {
            var a: Availability!
            if signedIn {
                let name = await getAccount()
                a = .yes(Authentication.ready(name))
                startPolling()
            } else {
                a = .pending(Authentication.anonymous({ [weak self] in
                    self?.authenticate()
                }))
            }
            defer {
                _availability.send(a)
            }
            return a
        }
        
        func sidecar() async throws -> Sidecar? {
            guard let client = DropboxClientsManager.authorizedClient else {
                throw ProviderError.notAuthenticated
            }
            do {
                let data = try await download(client: client, path: sidecarPath)
                return try JSONDecoder().decode(Sidecar.self, from: data)
            } catch ProviderError.fileNotFound {
                return Sidecar(uid: "", timestamp: .distantPast, device: "")
            }
        }
        
        func document() async throws -> Data? {
            guard let client = DropboxClientsManager.authorizedClient else {
                throw ProviderError.notAuthenticated
            }
            do {
                return try await download(client: client, path: documentPath)
            } catch ProviderError.fileNotFound {
                return Data()
            }
        }
        
        func send(document: Data, sidecar: Sidecar) async throws {
            guard let client = DropboxClientsManager.authorizedClient else {
                throw ProviderError.notAuthenticated
            }
            // Upload document
            try await upload(client: client, path: documentPath, data: document)
            // Upload sidecar and update cached hash
            let sidecarData = try JSONEncoder().encode(sidecar)
            let metadata = try await upload(client: client, path: sidecarPath, data: sidecarData)
            _lastSidecarHash = metadata.contentHash
        }
        
        func prepare() async throws {
            guard !_sdkInitialized else { return }
            _sdkInitialized = true
            // Set up dropbox sdk
            DropboxClientsManager.setupWithAppKeyDesktop("y6ijm2p3vqr7kt8")
            
            // Register authenticate callback
            NSAppleEventManager.shared().setEventHandler(self,
                                                         andSelector: #selector(handleGetURLEvent),
                                                         forEventClass: AEEventClass(kInternetEventClass),
                                                         andEventID: AEEventID(kAEGetURL))
        }
        
        func pause() async throws {
            stopPolling()
        }
        
        // MARK: - Polling
        
        private func startPolling() {
//            guard pollCancellable == nil else { return }
//            pollCancellable = Timer.publish(every: 10, on: .main, in: .common)
//                .autoconnect()
//                .sink { [weak self] _ in
//                    guard let self else { return }
//                    Task { await self.pollForChanges() }
//                }
            Task { await self.pollForChanges() }
        }
        
        private func stopPolling() {
            pollCancellable?.cancel()
            pollCancellable = nil
        }
        
        private func pollForChanges() async {
            guard let client = DropboxClientsManager.authorizedClient else { return }
            do {
                let hash = try await getContentHash(client: client, path: sidecarPath)
                guard hash != _lastSidecarHash else { return }
                _lastSidecarHash = hash
                let data = try await download(client: client, path: sidecarPath)
                let sidecar = try JSONDecoder().decode(Sidecar.self, from: data)
                _onArrive.send(sidecar)
            } catch ProviderError.fileNotFound {
                // Remote sidecar doesn't exist yet — nothing to pull
                return
            } catch {
                print("[Dropbox] poll failed: \(error)")
            }
        }
        
        // MARK: - Dropbox API Helpers
        
        private func getContentHash(client: DropboxClient, path: String) async throws -> String? {
            try await withCheckedThrowingContinuation { continuation in
                client.files.getMetadata(path: path).response { response, error in
                    if let metadata = response as? Files.FileMetadata {
                        continuation.resume(returning: metadata.contentHash)
                    } else if let error {
                        switch error {
                        case .routeError(let boxed, _, _, _):
                            switch boxed.unboxed as Files.GetMetadataError {
                            case .path(let lookupError):
                                switch lookupError {
                                case .notFound:
                                    continuation.resume(with: .failure(ProviderError.fileNotFound))
                                default:
                                    continuation.resume(with: .failure(ProviderError.apiError(lookupError.description)))
                                }
                            }
                        default:
                            continuation.resume(with: .failure(ProviderError.apiError(error.description)))
                        }
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
        
        private func download(client: DropboxClient, path: String) async throws -> Data {
            try await withCheckedThrowingContinuation { continuation in
                client.files.download(path: path).response { response, error in
                    if let response {
                        continuation.resume(returning: response.1)
                    } else if let error {
                        if case .routeError(let boxed, _, _, _) = error, case .path(let lookupError) = boxed.unboxed, case .notFound = lookupError {
                            continuation.resume(with: .failure(ProviderError.fileNotFound))
                        } else {
                            continuation.resume(with: .failure(ProviderError.apiError(error.description)))
                        }
                    } else {
                        continuation.resume(with: .failure(ProviderError.apiError("Unknown download error")))
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
                        continuation.resume(with: .failure(ProviderError.apiError(error.description)))
                    } else {
                        continuation.resume(with: .failure(ProviderError.apiError("Unknown upload error")))
                    }
                }
            }
        }
        
        // MARK: - OAuth
        
        @objc private func handleGetURLEvent(_ event: NSAppleEventDescriptor?, replyEvent: NSAppleEventDescriptor?) {
            if let aeEventDescriptor = event?.paramDescriptor(forKeyword: AEKeyword(keyDirectObject)) {
                if let urlStr = aeEventDescriptor.stringValue {
                    let url = URL(string: urlStr)!
                    let oauthCompletion: DropboxOAuthCompletion = { [weak self] in
                        if let authResult = $0 {
                            switch authResult {
                            case .success:
                                self?.startPolling()
                                Task {
                                    let name = await self?.getAccount()
                                    self?._availability.send(.yes(Authentication.ready(name)))
                                }
                            case .cancel:
                                self?._availability.send(.pending(Authentication.anonymous({ [weak self] in
                                    self?.authenticate()
                                })))
                            case .error(let error, _):
                                self?._availability.send(.pending(Authentication.error(error, { [weak self] in
                                    self?.authenticate()
                                })))
                            }
                        }
                    }
                    DropboxClientsManager.handleRedirectURL(url, includeBackgroundClient: false, completion: oauthCompletion)
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
        }
        
        // MARK: - Helpers
        
        var signedIn: Bool {
            DropboxClientsManager.authorizedClient != nil
        }
        
        func getAccount() async -> String? {
            guard let client = DropboxClientsManager.authorizedClient else {
                return nil
            }
            
            return await withCheckedContinuation { continuation in
                client.users.getCurrentAccount().response { account, error in
                    if let account {
                        continuation.resume(returning: account.name.displayName)
                    } else {
                        print("[Dropbox] Token is invalid or expired: \(String(describing: error))")
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
    }
}

extension Synchronizer.DropboxProvider {
    enum ProviderError: Error, LocalizedError {
        case notAuthenticated
        case fileNotFound
        case apiError(String)
        
        var errorDescription: String? {
            switch self {
            case .notAuthenticated:
                return "Dropbox is not authenticated"
            case .fileNotFound:
                return "File not found on Dropbox"
            case .apiError(let message):
                return "Dropbox API error: \(message)"
            }
        }
    }
}

extension Synchronizer.DropboxProvider {
    enum Authentication {
        case anonymous(() -> Void)
        case ready(String?)
        case error(Error, () -> Void)
    }
}

extension Synchronizer.DropboxProvider.Authentication: Synchronizer.Descriptor {
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
        case .ready(let name):
            var attr = AttributedString(name ?? "nobody")
            return attr
        }
    }
    
    var action: (() -> Void)? {
        switch self {
        case .anonymous(let action):
            return action
        case .error(_, let action):
            return action
        case .ready:
            return nil
        }
    }
}
