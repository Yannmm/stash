//
//  BaiduPanProvider.swift
//  Stash
//
//  Created by Rayman on 2026/8/18.
//

import Foundation
import Combine
import AppKit
import SwiftUI

extension Synchronizer {
    final class BaiduPanProvider: Provider {
        private static let clientId = "I5PDsDtk6M0sv821sdXmc585DzeUb8cn"
        private static let clientSecret = "oMebbuXLuLXXlODsssfsv1oyRUha4r3W"
        private static let redirectUri = "https://nustash-auth.yannmm.workers.dev/callback/baidupan"
        private static let authorizeURL = "https://openapi.baidu.com/oauth/2.0/authorize"
        private static let tokenURL = "https://openapi.baidu.com/oauth/2.0/token"
        private static let basePath = "/apps/Nustash"

        private let _onArrive = PassthroughSubject<Sidecar, Never>()
        var onArrive: AnyPublisher<Sidecar, Never> { _onArrive.eraseToAnyPublisher() }

        var availability: AnyPublisher<Availability, Never> { _availability.eraseToAnyPublisher() }
        private let _availability = CurrentValueSubject<Availability, Never>(.no(InitialPendingState(name: "BaiduPan")))

        private var pendingState: String?
        private var _anchor: UUID?
        private var pollTask: Task<Void, Never>?
        private var refreshTask: Task<Token, Error>?
        private var cancellables = Set<AnyCancellable>()

        private let sidecarPath: String = "\(basePath)/\(FileName.sidecar)"
        private let documentPath: String = "\(basePath)/\(FileName.document)"

        init() {
            NotificationCenter.default.publisher(for: .oauthCallback)
                .compactMap { $0.object as? URL }
                .filter { $0.host == "oauth" && $0.pathComponents.contains("baidupan") }
                .sink { [weak self] url in
                    Task { await self?.handleOAuthCallback(url: url) }
                }
                .store(in: &cancellables)
        }

        // MARK: - Protocol

        func prepare() async throws {
            await checkAvailability()
        }

        func pause() async throws {
            pollTask?.cancel()
            pollTask = nil
        }

        func checkAvailability() async {
            if let token = Keychain.load() {
                let name = await getAccountName(accessToken: token.accessToken)
                _availability.send(.yes(AuthStatus.ready(name, logout)))
                start()
            } else {
                _availability.send(.no(AuthStatus.anonymous({ [weak self] in
                    self?.authenticate()
                })))
            }
        }

        func sidecar() async throws -> Sidecar? {
            let accessToken = try await validAccessToken()
            do {
                let data = try await download(path: sidecarPath, accessToken: accessToken)
                return try JSONDecoder().decode(Sidecar.self, from: data)
            } catch BaiduError.fileNotFound {
                return nil
            }
        }

        func document() async throws -> Data? {
            let accessToken = try await validAccessToken()
            do {
                return try await download(path: documentPath, accessToken: accessToken)
            } catch BaiduError.fileNotFound {
                return nil
            }
        }

        func send(document: Data, sidecar: Sidecar) async throws {
            let accessToken = try await validAccessToken()
            try await upload(path: documentPath, data: document, accessToken: accessToken)
            let sidecarData = try JSONEncoder().encode(sidecar)
            try await upload(path: sidecarPath, data: sidecarData, accessToken: accessToken)
            _anchor = sidecar.uid
        }

        // MARK: - OAuth

        func authenticate() {
            let state = UUID().uuidString
            pendingState = state
            var components = URLComponents(string: Self.authorizeURL)!
            components.queryItems = [
                URLQueryItem(name: "response_type", value: "code"),
                URLQueryItem(name: "client_id", value: Self.clientId),
                URLQueryItem(name: "redirect_uri", value: Self.redirectUri),
                URLQueryItem(name: "scope", value: "basic,netdisk"),
                URLQueryItem(name: "state", value: state),
            ]
            NSWorkspace.shared.open(components.url!)
        }

        private func handleOAuthCallback(url: URL) async {
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let code = components.queryItems?.first(where: { $0.name == "code" })?.value,
                  let state = components.queryItems?.first(where: { $0.name == "state" })?.value,
                  state == pendingState else {
                _availability.send(.no(AuthStatus.error(BaiduError.authFailed, { [weak self] in
                    self?.authenticate()
                })))
                return
            }
            pendingState = nil

            do {
                let token = try await exchangeCode(code)
                try Keychain.save(token)
                let name = await getAccountName(accessToken: token.accessToken)
                _availability.send(.yes(AuthStatus.ready(name, logout)))
                start()
            } catch {
                _availability.send(.no(AuthStatus.error(error, { [weak self] in
                    self?.authenticate()
                })))
            }
            NSApp.activate(ignoringOtherApps: true)
        }

        private func exchangeCode(_ code: String) async throws -> Token {
            var components = URLComponents(string: Self.tokenURL)!
            components.queryItems = [
                URLQueryItem(name: "grant_type", value: "authorization_code"),
                URLQueryItem(name: "code", value: code),
                URLQueryItem(name: "client_id", value: Self.clientId),
                URLQueryItem(name: "client_secret", value: Self.clientSecret),
                URLQueryItem(name: "redirect_uri", value: Self.redirectUri),
            ]
            var request = URLRequest(url: components.url!)
            request.httpMethod = "GET"
            let (data, _) = try await URLSession.shared.data(for: request)
            let resp = try JSONDecoder().decode(TokenResponse.self, from: data)
            guard let access = resp.access_token, let refresh = resp.refresh_token else {
                throw BaiduError.tokenExchangeFailed(resp.error_description ?? "unknown")
            }
            return Token(accessToken: access, refreshToken: refresh)
        }

        // MARK: - Token Refresh

        private func validAccessToken() async throws -> String {
            guard let token = Keychain.load() else {
                _availability.send(.no(AuthStatus.anonymous({ [weak self] in
                    self?.authenticate()
                })))
                throw BaiduError.notAuthenticated
            }
            return token.accessToken
        }

        private func refreshAccessToken() async throws -> Token {
            if let existing = refreshTask {
                return try await existing.value
            }
            let task = Task<Token, Error> {
                defer { refreshTask = nil }
                guard let current = Keychain.load() else { throw BaiduError.notAuthenticated }
                var components = URLComponents(string: Self.tokenURL)!
                components.queryItems = [
                    URLQueryItem(name: "grant_type", value: "refresh_token"),
                    URLQueryItem(name: "refresh_token", value: current.refreshToken),
                    URLQueryItem(name: "client_id", value: Self.clientId),
                    URLQueryItem(name: "client_secret", value: Self.clientSecret),
                ]
                var request = URLRequest(url: components.url!)
                request.httpMethod = "GET"
                let (data, _) = try await URLSession.shared.data(for: request)
                let resp = try JSONDecoder().decode(TokenResponse.self, from: data)
                guard let access = resp.access_token, let refresh = resp.refresh_token else {
                    throw BaiduError.tokenExchangeFailed(resp.error_description ?? "unknown")
                }
                let newToken = Token(accessToken: access, refreshToken: refresh)
                try Keychain.save(newToken)
                return newToken
            }
            refreshTask = task
            return try await task.value
        }

        /// Executes a request; on 111 (token expired) refreshes and retries once.
        private func authedRequest<T>(_ work: @escaping (String) async throws -> T) async throws -> T {
            let token = try await validAccessToken()
            do {
                return try await work(token)
            } catch BaiduError.tokenExpired {
                let refreshed = try await refreshAccessToken()
                return try await work(refreshed.accessToken)
            }
        }

        // MARK: - Polling

        private func start() {
            guard pollTask == nil else { return }
            pollTask = Task { [weak self] in
                while !Task.isCancelled {
                    guard let self else { return }
                    await self.poll()
                    do {
                        try await Task.sleep(for: .seconds(10))
                    } catch { break }
                }
            }
        }

        private func poll() async {
            do {
                guard let sidecar = try await sidecar(),
                      let a = _anchor,
                      sidecar.uid != a else { return }
                _anchor = sidecar.uid
                _onArrive.send(sidecar)
            } catch BaiduError.fileNotFound {
                return
            } catch {
                print("[BaiduPan] poll failed: \(error)")
            }
        }

        // MARK: - File Operations

        private func download(path: String, accessToken: String) async throws -> Data {
            // Step 1: get download link via filemetas
            var components = URLComponents(string: "https://pan.baidu.com/rest/2.0/xpan/multimedia")!
            components.queryItems = [
                URLQueryItem(name: "method", value: "filemetas"),
                URLQueryItem(name: "access_token", value: accessToken),
                URLQueryItem(name: "fsids", value: "[\(try await getFileId(path: path, accessToken: accessToken))]"),
                URLQueryItem(name: "dlink", value: "1"),
            ]
            let (metaData, _) = try await URLSession.shared.data(from: components.url!)
            let meta = try JSONDecoder().decode(FileMetasResponse.self, from: metaData)
            guard let dlink = meta.list?.first?.dlink else { throw BaiduError.fileNotFound }

            // Step 2: download using dlink
            var dlURL = URLComponents(string: dlink)!
            dlURL.queryItems = (dlURL.queryItems ?? []) + [URLQueryItem(name: "access_token", value: accessToken)]
            var request = URLRequest(url: dlURL.url!)
            request.setValue("pan.baidu.com", forHTTPHeaderField: "User-Agent")
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                throw BaiduError.api("Download failed: \(http.statusCode)")
            }
            return data
        }

        private func getFileId(path: String, accessToken: String) async throws -> Int64 {
            var components = URLComponents(string: "https://pan.baidu.com/rest/2.0/xpan/file")!
            components.queryItems = [
                URLQueryItem(name: "method", value: "list"),
                URLQueryItem(name: "access_token", value: accessToken),
                URLQueryItem(name: "dir", value: Self.basePath),
            ]
            let (data, _) = try await URLSession.shared.data(from: components.url!)
            let resp = try JSONDecoder().decode(FileListResponse.self, from: data)
            let fileName = (path as NSString).lastPathComponent
            guard let file = resp.list?.first(where: { $0.server_filename == fileName }) else {
                throw BaiduError.fileNotFound
            }
            return file.fs_id
        }

        private func upload(path: String, data: Data, accessToken: String) async throws {
            // Step 1: precreate
            let blockList = "[\"\(data.md5Hex)\"]"
            var preBody = URLComponents()
            preBody.queryItems = [
                URLQueryItem(name: "path", value: path),
                URLQueryItem(name: "size", value: "\(data.count)"),
                URLQueryItem(name: "isdir", value: "0"),
                URLQueryItem(name: "autoinit", value: "1"),
                URLQueryItem(name: "block_list", value: blockList),
            ]

            var preReq = URLRequest(url: URL(string: "https://pan.baidu.com/rest/2.0/xpan/file?method=precreate&access_token=\(accessToken)")!)
            preReq.httpMethod = "POST"
            preReq.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            preReq.httpBody = preBody.query?.data(using: .utf8)
            let (preData, _) = try await URLSession.shared.data(for: preReq)
            let preResp = try JSONDecoder().decode(PrecreateResponse.self, from: preData)
            guard let uploadId = preResp.uploadid else {
                throw BaiduError.api("Precreate failed: \(String(data: preData, encoding: .utf8) ?? "")")
            }

            // Step 2: upload single slice
            let boundary = UUID().uuidString
            var uploadReq = URLRequest(url: URL(string: "https://d.pcs.baidu.com/rest/2.0/pcs/superfile2?method=upload&access_token=\(accessToken)&type=tmpfile&path=\(path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)&uploadid=\(uploadId)&partseq=0")!)
            uploadReq.httpMethod = "POST"
            uploadReq.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            var body = Data()
            body.append("--\(boundary)\r\nContent-Disposition: form-data; name=\"file\"; filename=\"chunk\"\r\nContent-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
            body.append(data)
            body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
            uploadReq.httpBody = body
            let (_, uploadResp) = try await URLSession.shared.data(for: uploadReq)
            if let http = uploadResp as? HTTPURLResponse, http.statusCode != 200 {
                throw BaiduError.api("Upload slice failed: \(http.statusCode)")
            }

            // Step 3: create (combine)
            var createBody = URLComponents()
            createBody.queryItems = [
                URLQueryItem(name: "path", value: path),
                URLQueryItem(name: "size", value: "\(data.count)"),
                URLQueryItem(name: "isdir", value: "0"),
                URLQueryItem(name: "uploadid", value: uploadId),
                URLQueryItem(name: "block_list", value: blockList),
            ]
            var createReq = URLRequest(url: URL(string: "https://pan.baidu.com/rest/2.0/xpan/file?method=create&access_token=\(accessToken)")!)
            createReq.httpMethod = "POST"
            createReq.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            createReq.httpBody = createBody.query?.data(using: .utf8)
            let (createData, _) = try await URLSession.shared.data(for: createReq)
            let createResp = try JSONDecoder().decode(CreateResponse.self, from: createData)
            if createResp.errno != 0 {
                throw BaiduError.api("Create failed: errno=\(createResp.errno ?? -1)")
            }
        }

        // MARK: - Helpers

        private func getAccountName(accessToken: String) async -> String? {
            var components = URLComponents(string: "https://pan.baidu.com/rest/2.0/xpan/nas")!
            components.queryItems = [
                URLQueryItem(name: "method", value: "uinfo"),
                URLQueryItem(name: "access_token", value: accessToken),
            ]
            guard let url = components.url,
                  let (data, _) = try? await URLSession.shared.data(from: url),
                  let resp = try? JSONDecoder().decode(UserInfoResponse.self, from: data) else {
                return nil
            }
            let name = resp.netdisk_name ?? resp.baidu_name
            return name?.isEmpty == true ? nil : name
        }

        func logout() {
            Keychain.delete()
            pollTask?.cancel()
            pollTask = nil
            Task { await checkAvailability() }
        }

        deinit {
            pollTask?.cancel()
        }
    }
}

// MARK: - API Response Models

extension Synchronizer.BaiduPanProvider {
    private struct TokenResponse: Decodable {
        let access_token: String?
        let refresh_token: String?
        let expires_in: Int?
        let error: String?
        let error_description: String?
    }

    private struct UserInfoResponse: Decodable {
        let baidu_name: String?
        let netdisk_name: String?
    }

    private struct FileListResponse: Decodable {
        let list: [FileItem]?
    }

    private struct FileItem: Decodable {
        let fs_id: Int64
        let server_filename: String
    }

    private struct FileMetasResponse: Decodable {
        let list: [FileMeta]?
    }

    private struct FileMeta: Decodable {
        let dlink: String?
    }

    private struct PrecreateResponse: Decodable {
        let uploadid: String?
        let errno: Int?
    }

    private struct CreateResponse: Decodable {
        let errno: Int?
    }
}

// MARK: - Errors

extension Synchronizer.BaiduPanProvider {
    enum BaiduError: Error, LocalizedError {
        case notAuthenticated
        case authFailed
        case tokenExpired
        case tokenExchangeFailed(String)
        case fileNotFound
        case api(String)

        var errorDescription: String? {
            switch self {
            case .notAuthenticated: return "Not signed in to BaiduPan"
            case .authFailed: return "Authorization failed"
            case .tokenExpired: return "Token expired"
            case .tokenExchangeFailed(let msg): return "Token exchange failed: \(msg)"
            case .fileNotFound: return "File not found"
            case .api(let msg): return msg
            }
        }
    }
}

// MARK: - AuthStatus

extension Synchronizer.BaiduPanProvider {
    enum AuthStatus {
        case anonymous(() -> Void)
        case ready(String?, () -> Void)
        case error(Error, () -> Void)
    }
}

extension Synchronizer.BaiduPanProvider.AuthStatus: Synchronizer.Descriptor {
    func describe() -> AttributedString {
        switch self {
        case .anonymous:
            var attr = AttributedString("Please sign in BaiduPan.")
            attr.foregroundColor = .secondary
            if let range = attr.range(of: "sign in") {
                attr[range].foregroundColor = Color.theme
                attr[range].link = URL(string: "action://abc")
            }
            return attr
        case .error(let e, _):
            var attr = AttributedString("An error happened, please try again: \(e.localizedDescription)")
            attr.foregroundColor = .secondary
            if let range = attr.range(of: "try again") {
                attr[range].foregroundColor = Color.theme
                attr[range].link = URL(string: "action://abc")
            }
            return attr
        case .ready(let name, _):
            var attr = AttributedString("Already signed in BaiduPan")
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
        case .anonymous(let action): action()
        case .error(_, let action): action()
        case .ready(_, let action): action()
        }
    }
}

// MARK: - Notification Name

extension Notification.Name {
    static let oauthCallback = Notification.Name("OAuthCallbackReceived")
}

// MARK: - Data MD5

import CommonCrypto

extension Data {
    var md5Hex: String {
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        withUnsafeBytes { CC_MD5($0.baseAddress, CC_LONG(count), &digest) }
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
