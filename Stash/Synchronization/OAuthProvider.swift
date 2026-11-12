//
//  OAuthProvider.swift
//  Stash
//
//  Created by Yan Meng on 2026/11/12.
//

import Foundation
import Combine

extension Synchronizer {
    /// Shared skeleton for OAuth-backed, polled remotes (Dropbox, Baidu Pan): auth readiness, redirect
    /// observation, polling lifecycle and the sidecar / document layout inside `directory`.
    ///
    /// Subclasses override the hooks under `Subclass Hooks`.
    class OAuthProvider: RemoteProvider, Polling {

        var readiness: AnyPublisher<Result<any ProviderReadiness, Error>, Never> { _authentication.eraseToReadinessPublisher() }

        private let _authentication: CurrentValueSubject<Result<AuthStatus, Error>, Never>

        var strayError: AnyPublisher<(String, Error)?, Never> { _strayError.eraseToAnyPublisher() }

        private let _strayError = PassthroughSubject<(String, Error)?, Never>()

        var onArrive: AnyPublisher<Sidecar?, Never> { _onArrive.eraseToAnyPublisher() }

        func setOnArrive(_ sidecar: Sidecar?) { _onArrive.send(sidecar) }

        private let _onArrive = PassthroughSubject<Sidecar?, Never>()

        var poltask: Task<Void, Never>?

        private let name: String

        private let sidecarPath: String

        private let documentPath: String

        private var accountName: String?

        private var cancellables = Set<AnyCancellable>()

        /// - Parameters:
        ///   - name: Display name, e.g. "Dropbox".
        ///   - directory: Remote folder holding the files, "" for the root.
        init(name: String, directory: String) {
            self.name = name
            self.sidecarPath = "\(directory)/\(FileName.sidecar)"
            self.documentPath = "\(directory)/\(FileName.document)"
            self._authentication = CurrentValueSubject(.success(.initializing(name)))
        }

        // MARK: - Subclass Hooks

        /// Whether credentials are stored locally, it doesn't validate them.
        var isAuthorized: Bool { fatalError("Subclass must override") }

        func fetchAccountName() async throws -> String? { fatalError("Subclass must override") }

        /// Throws `SyncError.fileNotFound` if `path` is absent on remote.
        func download(path: String) async throws -> Data { fatalError("Subclass must override") }

        /// Overwrites `path` on remote.
        func upload(path: String, data: Data) async throws { fatalError("Subclass must override") }

        /// Starts the OAuth flow, its redirect comes back through `handleRedirect(_:)`.
        func authenticate() { fatalError("Subclass must override") }

        /// Drops stored credentials.
        func unlink() { fatalError("Subclass must override") }

        func isRedirect(_ url: URL) -> Bool { fatalError("Subclass must override") }

        func handleRedirect(_ url: URL) { fatalError("Subclass must override") }

        // MARK: - Protocol

        func prepare() async throws {
            observe(true)
            // Re-check on every prepare so polling restarts after pause
            await checkAuth()
        }

        func pause() async throws {
            observe(false)
            pausepol()
        }

        func sidecar() async throws -> Sidecar {
            let data = try await download(path: sidecarPath)
            return try JSONDecoder().decode(Sidecar.self, from: data)
        }

        func document() async throws -> Data {
            return try await download(path: documentPath)
        }

        func send(document: Data, sidecar: Sidecar) async throws {
            // Document first, so a sidecar on remote never points at a stale document
            try await upload(path: documentPath, data: document)
            try await upload(path: sidecarPath, data: try JSONEncoder().encode(sidecar))
        }

        func onPollError(_ error: Error) {
            _strayError.send(("\(name) poll", error))
        }

        // MARK: - Auth

        func checkAuth() async {
            do {
                if isAuthorized {
                    if accountName == nil {
                        accountName = try await fetchAccountName()
                    }
                    _authentication.send(.success(.ready(accountName, { [weak self] in self?.logout() })))
                    startpol()
                } else {
                    signedOut()
                }
            } catch {
                _authentication.send(.failure(error))
            }
        }

        /// Reports anonymous, e.g. when the user cancels the OAuth flow.
        func signedOut() {
            _authentication.send(.success(.anonymous({ [weak self] in self?.authenticate() })))
        }

        func authFailed(_ error: Error) {
            _authentication.send(.failure(error))
        }

        private func logout() {
            accountName = nil
            unlink()
            pausepol()
            Task {
                await checkAuth()
            }
        }

        private func observe(_ flag: Bool) {
            cancellables.forEach({ $0.cancel() })
            cancellables.removeAll()
            if flag {
                NotificationCenter.default.publisher(for: .onUrlEvent)
                    .compactMap { $0.object as? URL }
                    .filter { [weak self] in self?.isRedirect($0) == true }
                    .sink { [weak self] url in
                        self?.handleRedirect(url)
                    }
                    .store(in: &cancellables)

                NetworkMonitor.shared.onChange.sink { [weak self] in
                    // Restart polling so a backed-off loop and its stale error don't outlive the network change
                    self?.pausepol()
                    Task {
                        await self?.checkAuth()
                    }
                }
                .store(in: &cancellables)
            }
        }

        deinit {
            pausepol()
        }
    }
}
