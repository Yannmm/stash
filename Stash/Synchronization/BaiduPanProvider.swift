//
//  BaiduPanProvider.swift
//  Stash
//
//  Created by Rayman on 2026/8/18.
//

import Foundation
import AppKit

fileprivate extension Synchronizer.BaiduPanProvider {
    enum Constant {
        static let clientId = "I5PDsDtk6M0sv821sdXmc585DzeUb8cn"
        static let clientSecret = "oMebbuXLuLXXlODsssfsv1oyRUha4r3W"
        static let redirectUri = "https://auth.513410.xyz/callback/baidupan"
        static let authorizeUrl = "https://openapi.baidu.com/oauth/2.0/authorize"
        static let tokenUrl = "https://openapi.baidu.com/oauth/2.0/token"
        static let basePath = "/apps/Nustash"
    }
}

extension Synchronizer {
    final class BaiduPanProvider: OAuthProvider {
        
        private var _state: String?
        
        private var _refreshTask: Task<Token, Error>?
        
        init() {
            super.init(name: "Baidu Pan", directory: Constant.basePath)
        }
        
        // MARK: - Overrides
        
        override var isAuthorized: Bool { Keychain.load() != nil }
        
        override func isRedirect(_ url: URL) -> Bool {
            url.host == "oauth" && url.pathComponents.contains("baidupan")
        }
        
        override func fetchAccountName() async throws -> String? {
            try await ensure { token in
                let resp: UserInfoResponse = try await self.fetch(
                    "https://pan.baidu.com/rest/2.0/xpan/nas",
                    query: ["method": "uinfo", "access_token": token]
                )
                let netdiskName = resp.netdisk_name ?? ""
                return netdiskName.isEmpty ? resp.baidu_name : netdiskName
            }
        }
        
        override func download(path: String) async throws -> Data {
            try await ensure { token in
                // Step 1: get download link via filemetas
                let fsid = try await self.getFileId(path: path, accessToken: token)
                let meta: FileMetasResponse = try await self.fetch(
                    "https://pan.baidu.com/rest/2.0/xpan/multimedia",
                    query: ["method": "filemetas", "access_token": token, "fsids": "[\(fsid)]", "dlink": "1"]
                )
                guard let dlink = meta.list?.first?.dlink, var components = URLComponents(string: dlink) else {
                    throw SyncError.fileNotFound(path)
                }
                
                // Step 2: download using dlink
                components.queryItems = (components.queryItems ?? []) + [URLQueryItem(name: "access_token", value: token)]
                var request = URLRequest(url: try components.validUrl())
                request.setValue("pan.baidu.com", forHTTPHeaderField: "User-Agent")
                return try await self.perform(request, step: "Download")
            }
        }
        
        override func upload(path: String, data: Data) async throws {
            try await ensure { token in
                // Baidu uses MD5 hashes in the block list.
                let blockList = "[\"\(data.md5Hex)\"]"
                let fileUrl = "https://pan.baidu.com/rest/2.0/xpan/file"
                
                // Step 1: Precreate, rtype 3 = overwrite existing file
                let pre: PrecreateResponse = try await self.fetch(
                    fileUrl,
                    query: ["method": "precreate", "access_token": token],
                    form: ["path": path, "size": "\(data.count)", "isdir": "0", "autoinit": "1", "block_list": blockList, "rtype": "3"]
                )
                guard let uploadId = pre.uploadid else {
                    throw SyncError.api("Precreate failed: no uploadid")
                }
                
                // Step 2: Upload the single slice
                var components = URLComponents(string: "https://d.pcs.baidu.com/rest/2.0/pcs/superfile2")!
                components.setQuery(["method": "upload", "access_token": token, "type": "tmpfile", "path": path, "uploadid": uploadId, "partseq": "0"])
                let boundary = "Boundary-\(UUID().uuidString)"
                var request = URLRequest(url: try components.validUrl())
                request.httpMethod = "POST"
                request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                var body = Data()
                body.append(Data("--\(boundary)\r\n".utf8))
                body.append(Data("Content-Disposition: form-data; name=\"file\"; filename=\"chunk\"\r\n".utf8))
                body.append(Data("Content-Type: application/octet-stream\r\n\r\n".utf8))
                body.append(data)
                body.append(Data("\r\n--\(boundary)--\r\n".utf8))
                request.httpBody = body
                let sliceData = try await self.perform(request, step: "Upload slice")
                // superfile2 normally returns JSON containing errno.
                if let slice = try? JSONDecoder().decode(ErrnoResponse.self, from: sliceData) {
                    try Self.checkErrno(slice.errno)
                }
                
                // Step 3: Create / finalize
                let _: ErrnoResponse = try await self.fetch(
                    fileUrl,
                    query: ["method": "create", "access_token": token],
                    form: ["path": path, "size": "\(data.count)", "isdir": "0", "uploadid": uploadId, "block_list": blockList, "rtype": "3"]
                )
            }
        }
        
        override func unlink() {
            Keychain.delete()
        }
        
        // MARK: - OAuth
        
        override func authenticate() {
            let state = UUID().uuidString
            _state = state
            var components = URLComponents(string: Constant.authorizeUrl)!
            components.setQuery([
                "response_type": "code",
                "client_id": Constant.clientId,
                "redirect_uri": Constant.redirectUri,
                "scope": "basic,netdisk",
                "state": state,
            ])
            NSWorkspace.shared.open(components.url!)
        }
        
        override func handleRedirect(_ url: URL) {
            let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
            func value(_ name: String) -> String? { items.first(where: { $0.name == name })?.value }
            
            guard let state = value("state"), state == _state else {
                authFailed(SyncError.malformedCallbackUrl(url))
                return
            }
            _state = nil
            NSApp.activate(ignoringOtherApps: true)
            
            // User denied the authorization, same as Dropbox's cancel
            guard let code = value("code") else {
                if value("error") != nil {
                    signedOut()
                } else {
                    authFailed(SyncError.malformedCallbackUrl(url))
                }
                return
            }
            
            Task { [weak self] in
                guard let self else { return }
                do {
                    try Keychain.save(try await self.requestToken([
                        "grant_type": "authorization_code",
                        "code": code,
                        "redirect_uri": Constant.redirectUri,
                    ]))
                    await self.checkAuth()
                } catch {
                    self.authFailed(error)
                }
            }
        }
        
        private func requestToken(_ query: [String: String]) async throws -> Token {
            var components = URLComponents(string: Constant.tokenUrl)!
            components.setQuery(query.merging(["client_id": Constant.clientId, "client_secret": Constant.clientSecret]) { a, _ in a })
            let (data, _) = try await URLSession.shared.data(from: try components.validUrl())
            let resp = try JSONDecoder().decode(TokenResponse.self, from: data)
            guard let access = resp.access_token, let refresh = resp.refresh_token else {
                throw SyncError.tokenExchangeFailure(resp.error_description)
            }
            return Token(accessToken: access, refreshToken: refresh)
        }
        
        // MARK: - Token Refresh
        
        /// Coalesces concurrent refreshes into one request.
        private func refreshAccessToken() async throws -> Token {
            if let existing = _refreshTask {
                return try await existing.value
            }
            let task = Task<Token, Error> {
                guard let current = Keychain.load() else { throw SyncError.unauthenticated }
                let token = try await requestToken(["grant_type": "refresh_token", "refresh_token": current.refreshToken])
                try Keychain.save(token)
                return token
            }
            _refreshTask = task
            // Cleared here rather than inside the task, which may finish before it's assigned
            defer { _refreshTask = nil }
            return try await task.value
        }
        
        /// Executes a request; on 111 (token expired) refreshes and retries once.
        private func ensure<T>(_ work: @escaping (String) async throws -> T) async throws -> T {
            guard let token = Keychain.load() else {
                throw SyncError.unauthenticated
            }
            do {
                return try await work(token.accessToken)
            } catch SyncError.tokenExpired {
                let refreshed = try await refreshAccessToken()
                return try await work(refreshed.accessToken)
            }
        }
        
        // MARK: - Helpers
        
        private func getFileId(path: String, accessToken: String) async throws -> Int64 {
            let resp: FileListResponse
            do {
                resp = try await fetch(
                    "https://pan.baidu.com/rest/2.0/xpan/file",
                    query: ["method": "list", "access_token": accessToken, "dir": Constant.basePath]
                )
            } catch Errno.notFound {
                // The app folder doesn't exist until the first upload
                throw SyncError.fileNotFound(path)
            }
            let fileName = (path as NSString).lastPathComponent
            guard let file = resp.list?.first(where: { $0.server_filename == fileName }) else {
                throw SyncError.fileNotFound(path)
            }
            return file.fs_id
        }
        
        /// Sends a GET (or a form POST if `form` is given) and decodes the JSON response, throwing on non-zero errno.
        private func fetch<T: Decodable & BaiduResponse>(
            _ url: String,
            query: [String: String],
            form: [String: String]? = nil
        ) async throws -> T {
            var components = URLComponents(string: url)!
            components.setQuery(query)
            var request = URLRequest(url: try components.validUrl())
            if let form {
                var body = URLComponents()
                body.setQuery(form)
                request.httpMethod = "POST"
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                request.httpBody = body.percentEncodedQuery?.data(using: .utf8)
            }
            let data = try await perform(request, step: query["method"] ?? url)
            let resp = try JSONDecoder().decode(T.self, from: data)
            try Self.checkErrno(resp.errno)
            return resp
        }
        
        /// Sends `request`, throwing on a non-2xx status.
        private func perform(_ request: URLRequest, step: String) async throws -> Data {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                // Baidu reports some errors (e.g. expired token) with a 4xx status and an errno body
                if let resp = try? JSONDecoder().decode(ErrnoResponse.self, from: data) {
                    try Self.checkErrno(resp.errno)
                }
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                throw SyncError.api("\(step) HTTP error: \(statusCode), \(String(data: data, encoding: .utf8) ?? "")")
            }
            return data
        }
        
        private static func checkErrno(_ errno: Int?) throws {
            guard let errno, errno != 0 else { return }
            if errno == 111 || errno == -6 { throw SyncError.tokenExpired }
            if errno == -9 { throw Errno.notFound }
            throw SyncError.api("API error: errno=\(errno)")
        }
    }
}

// MARK: - API Response Models

private protocol BaiduResponse {
    var errno: Int? { get }
}

extension Synchronizer.BaiduPanProvider {
    private struct TokenResponse: Decodable {
        let access_token: String?
        let refresh_token: String?
        let expires_in: Int?
        let error: String?
        let error_description: String?
    }
    
    private enum Errno: Error {
        /// -9, file or directory doesn't exist
        case notFound
    }
    
    private struct UserInfoResponse: Decodable, BaiduResponse {
        let errno: Int?
        let baidu_name: String?
        let netdisk_name: String?
    }
    
    private struct FileListResponse: Decodable, BaiduResponse {
        let errno: Int?
        let list: [FileItem]?
    }
    
    private struct FileItem: Decodable {
        let fs_id: Int64
        let server_filename: String
    }
    
    private struct FileMetasResponse: Decodable, BaiduResponse {
        let errno: Int?
        let list: [FileMeta]?
    }
    
    private struct FileMeta: Decodable {
        let dlink: String?
    }
    
    private struct PrecreateResponse: Decodable, BaiduResponse {
        let uploadid: String?
        let errno: Int?
    }
    
    private struct ErrnoResponse: Decodable, BaiduResponse {
        let errno: Int?
    }
}

// MARK: - URLComponents

fileprivate extension URLComponents {
    mutating func setQuery(_ query: [String: String]) {
        queryItems = query.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) }
    }
    
    func validUrl() throws -> URL {
        guard let url else { throw Synchronizer.SyncError.unexpected("Malformed URL: \(self)") }
        return url
    }
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
