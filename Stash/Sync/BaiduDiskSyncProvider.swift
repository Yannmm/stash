//
//  BaiduDiskSyncProvider.swift
//  Stash
//
//  Created by Cursor on 2026/4/13.
//

import Foundation

final class BaiduDiskSyncProvider: SyncProvider {
    let method: SyncMethod = .baiduDisk
    let displayName = SyncMethod.baiduDisk.displayName

    private enum SecretKey {
        static let clientSecret = "sync.baidu.clientSecret"
        static let token = "sync.baidu.oauthToken"
    }

    enum OAuthCallbackResult {
        case ignored
        case handled
    }

    private let client: BaiduDiskClient
    private let pieceSaver: PieceSaver
    private let keychain: KeychainStore
    private let store: StashPayloadStore

    init(client: BaiduDiskClient, pieceSaver: PieceSaver, keychain: KeychainStore, store: StashPayloadStore) {
        self.client = client
        self.pieceSaver = pieceSaver
        self.keychain = keychain
        self.store = store
    }

    var clientID: String {
        get { pieceSaver.value(for: .baiduClientID) ?? "" }
        set { pieceSaver.save(for: .baiduClientID, value: newValue) }
    }

    var redirectURI: String {
        get { pieceSaver.value(for: .baiduRedirectURI) ?? Self.defaultRedirectURI }
        set { pieceSaver.save(for: .baiduRedirectURI, value: newValue) }
    }

    var remoteDirectory: String {
        get { pieceSaver.value(for: .baiduRemoteDirectory) ?? "/apps/Stash" }
        set { pieceSaver.save(for: .baiduRemoteDirectory, value: newValue) }
    }

    func updateConfiguration(clientID: String, clientSecret: String, redirectURI: String, remoteDirectory: String) throws {
        self.clientID = clientID.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedRedirectURI = redirectURI.trimmingCharacters(in: .whitespacesAndNewlines)
        self.redirectURI = normalizedRedirectURI.isEmpty ? Self.defaultRedirectURI : normalizedRedirectURI
        self.remoteDirectory = normalizedRemoteDirectory(remoteDirectory)
        try keychain.set(clientSecret, for: SecretKey.clientSecret)
    }

    func authorizationURL() throws -> URL {
        guard !clientID.isEmpty else {
            throw SyncProviderError.needsConfiguration("Enter your Baidu client ID first.")
        }
        guard !redirectURI.isEmpty else {
            throw SyncProviderError.needsConfiguration("Enter the Baidu redirect URI registered for your app.")
        }
        guard keychain.string(for: SecretKey.clientSecret)?.isEmpty == false else {
            throw SyncProviderError.needsConfiguration("Enter your Baidu client secret first.")
        }
        let state = UUID().uuidString
        pieceSaver.save(for: .baiduOAuthState, value: state)
        return try client.authorizationURL(clientID: clientID, redirectURI: redirectURI, state: state)
    }

    func completeAuthorization(code: String) async throws {
        let code = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else {
            throw SyncProviderError.needsConfiguration("Missing Baidu authorization code.")
        }
        guard let secret = keychain.string(for: SecretKey.clientSecret) else {
            throw SyncProviderError.needsConfiguration("Missing Baidu client secret.")
        }

        let token = try await client.exchangeCode(
            clientID: clientID,
            clientSecret: secret,
            code: code,
            redirectURI: redirectURI
        )
        try saveToken(token)
        pieceSaver.save(for: .baiduOAuthState, value: nil)
    }

    func handleOAuthRedirect(_ url: URL) async throws -> OAuthCallbackResult {
        guard isMatchingRedirect(url) else {
            return .ignored
        }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []
        if let error = queryItems.first(where: { $0.name == "error" })?.value {
            let description = queryItems.first(where: { $0.name == "error_description" })?.value ?? error
            throw SyncProviderError.notAuthenticated(description)
        }

        guard let returnedState = queryItems.first(where: { $0.name == "state" })?.value,
              let expectedState: String = pieceSaver.value(for: .baiduOAuthState),
              returnedState == expectedState else {
            throw SyncProviderError.notAuthenticated("The Baidu sign-in response could not be verified.")
        }

        guard let code = queryItems.first(where: { $0.name == "code" })?.value else {
            throw SyncProviderError.notAuthenticated("Baidu did not return an authorization code.")
        }

        try await completeAuthorization(code: code)
        return .handled
    }

    func authState() -> SyncProviderAuthState {
        if clientID.isEmpty || redirectURI.isEmpty {
            return .needsConfiguration("Provide your Baidu app credentials to enable direct sync.")
        }
        if currentToken() != nil {
            return .signedIn("Connected to \(remoteDirectory)")
        }
        return .signedOut
    }

    func prepare() async throws {
        _ = try await validAccessToken()
    }

    func fetchRemoteSnapshot() async throws -> SyncRemoteSnapshot? {
        let accessToken = try await validAccessToken()
        let payloadFile = try await client.file(
            named: StashPayloadStore.Constant.dataFileName,
            in: remoteDirectory,
            accessToken: accessToken
        )

        guard let payloadFile, let payloadFSID = payloadFile.fsID else {
            return nil
        }

        let payload = try await client.downloadFile(fsID: payloadFSID, accessToken: accessToken)
        let metadataFile = try await client.file(
            named: StashPayloadStore.Constant.metadataFileName,
            in: remoteDirectory,
            accessToken: accessToken
        )

        let metadata: SyncMetadata
        if let metadataFSID = metadataFile?.fsID {
            let metadataData = try await client.downloadFile(fsID: metadataFSID, accessToken: accessToken)
            metadata = (try? store.deserializeMetadata(from: metadataData)) ??
                SyncMetadata(
                    deviceId: "baidu",
                    contentHash: store.contentHash(for: payload),
                    revision: metadataFile?.md5 ?? UUID().uuidString,
                    updatedAt: Date(timeIntervalSince1970: metadataFile?.serverMtime ?? Date().timeIntervalSince1970)
                )
        } else {
            metadata = SyncMetadata(
                deviceId: "baidu",
                contentHash: store.contentHash(for: payload),
                revision: payloadFile.md5 ?? UUID().uuidString,
                updatedAt: Date(timeIntervalSince1970: payloadFile.serverMtime ?? Date().timeIntervalSince1970)
            )
        }

        return SyncRemoteSnapshot(
            payloadData: payload,
            metadata: metadata,
            providerRevision: metadata.revision
        )
    }

    func upload(payloadData: Data, metadata: SyncMetadata, previousRevision: String?) async throws -> SyncUploadResponse {
        let accessToken = try await validAccessToken()

        if let previousRevision,
           let existing = try await fetchRemoteSnapshot(),
           existing.metadata.revision != previousRevision,
           existing.metadata.contentHash != metadata.contentHash {
            throw SyncProviderError.conflictDetected
        }

        let payloadPath = remotePath(for: StashPayloadStore.Constant.dataFileName)
        _ = try await client.uploadFile(data: payloadData, path: payloadPath, accessToken: accessToken)
        let metadataData = try store.serialize(metadata: metadata)
        _ = try await client.uploadFile(
            data: metadataData,
            path: remotePath(for: StashPayloadStore.Constant.metadataFileName),
            accessToken: accessToken
        )

        return SyncUploadResponse(providerRevision: metadata.revision, metadata: metadata)
    }

    func signOut() async throws {
        try keychain.remove(SecretKey.token)
    }

    private func remotePath(for filename: String) -> String {
        normalizedRemoteDirectory(remoteDirectory).appending("/\(filename)")
    }

    private func normalizedRemoteDirectory(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "/apps/Stash"
        }
        return trimmed.hasPrefix("/") ? trimmed : "/\(trimmed)"
    }

    private func currentToken() -> BaiduOAuthToken? {
        guard let raw = keychain.string(for: SecretKey.token),
              let data = raw.data(using: .utf8) else {
            return nil
        }
        return try? JSONDecoder().decode(BaiduOAuthToken.self, from: data)
    }

    private func saveToken(_ token: BaiduOAuthToken) throws {
        let data = try JSONEncoder().encode(token)
        try keychain.set(String(decoding: data, as: UTF8.self), for: SecretKey.token)
    }

    private func isMatchingRedirect(_ url: URL) -> Bool {
        guard let expected = URL(string: redirectURI) else { return false }
        let candidatePath = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let expectedPath = expected.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return url.scheme?.caseInsensitiveCompare(expected.scheme ?? "") == .orderedSame &&
            url.host?.caseInsensitiveCompare(expected.host ?? "") == .orderedSame &&
            candidatePath == expectedPath
    }

    private func validAccessToken() async throws -> String {
        guard !clientID.isEmpty, !redirectURI.isEmpty else {
            throw SyncProviderError.needsConfiguration("Configure the Baidu client ID and redirect URI first.")
        }
        guard let secret = keychain.string(for: SecretKey.clientSecret), !secret.isEmpty else {
            throw SyncProviderError.needsConfiguration("Configure the Baidu client secret first.")
        }
        guard var token = currentToken() else {
            throw SyncProviderError.notAuthenticated(displayName)
        }

        if token.isExpired {
            token = try await client.refreshToken(
                clientID: clientID,
                clientSecret: secret,
                refreshToken: token.refreshToken
            )
            try saveToken(token)
        }

        return token.accessToken
    }
}

extension BaiduDiskSyncProvider {
    static let defaultRedirectURI = "nustash://oauth/baidu"
}
