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

fileprivate extension Synchronizer.BaiduPanProvider {
    enum Constant {
        static let clientId = "I5PDsDtk6M0sv821sdXmc585DzeUb8cn"
        static let clientSecret = "oMebbuXLuLXXlODsssfsv1oyRUha4r3W"
        static let redirectUri = "https://nustash-auth.yannmm.workers.dev/callback/baidupan"
        static let authorizeUrl = "https://openapi.baidu.com/oauth/2.0/authorize"
        static let tokenUrl = "https://openapi.baidu.com/oauth/2.0/token"
        static let basePath = "/apps/Nustash"
        static let sidecarPath: String = "\(basePath)/\(Synchronizer.FileName.sidecar)"
        static let documentPath: String = "\(basePath)/\(Synchronizer.FileName.document)"
    }
}

extension Synchronizer {
    final class BaiduPanProvider: Provider, Polling {
        
        private let _onArrive = PassthroughSubject<Sidecar, Never>()
        
        var onArrive: AnyPublisher<Sidecar, Never> { _onArrive.eraseToAnyPublisher() }
        
        func setOnArrive(_ sidecar: Sidecar) { _onArrive.send(sidecar) }
        
        var availability: AnyPublisher<Availability, Never> { _availability.eraseToAnyPublisher() }
        
        private let _availability = CurrentValueSubject<Availability, Never>(.no(InitialPendingState(name: "BaiduPan")))
        
        private var _state: String?
        
        var polanchor: UUID?
        
        var poltask: Task<Void, Never>?
        
        private var _refreshTask: Task<Token, Error>?
        
        private var cancellables = Set<AnyCancellable>()
        
        init() {
            NotificationCenter.default.publisher(for: .onUrlEvent)
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
        
        private func checkAvailability() async {
            if let token = Keychain.load() {
                let name = await getAccountName(accessToken: token.accessToken)
                _availability.send(.yes(AuthStatus.ready(name, { [weak self] _ in
                    self?.logout()
                })))
                startpol()
            } else {
                _availability.send(.no(AuthStatus.anonymous({ [weak self] _ in
                    self?.authenticate()
                })))
            }
        }
        
        func sidecar() async throws -> Sidecar {
            try await ensure { token in
                let data = try await self.download(path: Constant.sidecarPath, accessToken: token)
                return try JSONDecoder().decode(Sidecar.self, from: data)
            }
        }
        
        func document() async throws -> Data {
            try await ensure { token in
                return try await self.download(path: Constant.documentPath, accessToken: token)
            }
        }
        
        func send(document: Data, sidecar: Sidecar) async throws {
            try await ensure { token in
                try await self.upload(path: Constant.documentPath, data: document, accessToken: token)
                try await self.upload(path: Constant.sidecarPath, data: try JSONEncoder().encode(sidecar), accessToken: token)
            }
            polanchor = sidecar.uid
        }
        
        // MARK: - OAuth
        
        func authenticate() {
            let state = UUID().uuidString
            _state = state
            var components = URLComponents(string: Constant.authorizeUrl)!
            components.queryItems = [
                URLQueryItem(name: "response_type", value: "code"),
                URLQueryItem(name: "client_id", value: Constant.clientId),
                URLQueryItem(name: "redirect_uri", value: Constant.redirectUri),
                URLQueryItem(name: "scope", value: "basic,netdisk"),
                URLQueryItem(name: "state", value: state),
            ]
            NSWorkspace.shared.open(components.url!)
        }
        
        private func handleOAuthCallback(url: URL) async {
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let code = components.queryItems?.first(where: { $0.name == "code" })?.value,
                  let state = components.queryItems?.first(where: { $0.name == "state" })?.value,
                  state == _state else {
                _availability.send(.no(AuthStatus.error(SomeError.authFailed, { [weak self] _ in
                    self?.authenticate()
                })))
                return
            }
            _state = nil
            
            do {
                let token = try await exchangeCode(code)
                try Keychain.save(token)
                let name = await getAccountName(accessToken: token.accessToken)
                _availability.send(.yes(AuthStatus.ready(name, { [weak self] _ in
                    self?.logout()
                })))
                startpol()
            } catch {
                _availability.send(.no(AuthStatus.error(error, { [weak self] _ in
                    self?.authenticate()
                })))
            }
            await NSApp.activate()
        }
        
        private func exchangeCode(_ code: String) async throws -> Token {
            var components = URLComponents(string: Constant.tokenUrl)!
            components.queryItems = [
                URLQueryItem(name: "grant_type", value: "authorization_code"),
                URLQueryItem(name: "code", value: code),
                URLQueryItem(name: "client_id", value: Constant.clientId),
                URLQueryItem(name: "client_secret", value: Constant.clientSecret),
                URLQueryItem(name: "redirect_uri", value: Constant.redirectUri),
            ]
            var request = URLRequest(url: components.url!)
            request.httpMethod = "GET"
            let (data, _) = try await URLSession.shared.data(for: request)
            let resp = try JSONDecoder().decode(TokenResponse.self, from: data)
            guard let access = resp.access_token, let refresh = resp.refresh_token else {
                throw SomeError.tokenExchangeFailed(resp.error_description ?? "Exchange token failed")
            }
            return Token(accessToken: access, refreshToken: refresh)
        }
        
        // MARK: - Token Refresh
        
        private func getAccessToken() async throws -> String {
            guard let token = Keychain.load() else {
                _availability.send(.no(AuthStatus.anonymous({ [weak self] _ in
                    self?.authenticate()
                })))
                throw SomeError.unauthenticated
            }
            return token.accessToken
        }
        
        private func refreshAccessToken() async throws -> Token {
            if let existing = _refreshTask {
                return try await existing.value
            }
            let task = Task<Token, Error> {
                defer { _refreshTask = nil }
                guard let current = Keychain.load() else { throw SomeError.unauthenticated }
                var components = URLComponents(string: Constant.tokenUrl)!
                components.queryItems = [
                    URLQueryItem(name: "grant_type", value: "refresh_token"),
                    URLQueryItem(name: "refresh_token", value: current.refreshToken),
                    URLQueryItem(name: "client_id", value: Constant.clientId),
                    URLQueryItem(name: "client_secret", value: Constant.clientSecret),
                ]
                var request = URLRequest(url: components.url!)
                request.httpMethod = "GET"
                let (data, _) = try await URLSession.shared.data(for: request)
                let resp = try JSONDecoder().decode(TokenResponse.self, from: data)
                guard let access = resp.access_token, let refresh = resp.refresh_token else {
                    throw SomeError.tokenExchangeFailed(resp.error_description ?? "unknown")
                }
                let newToken = Token(accessToken: access, refreshToken: refresh)
                try Keychain.save(newToken)
                return newToken
            }
            _refreshTask = task
            return try await task.value
        }
        
        /// Executes a request; on 111 (token expired) refreshes and retries once.
        private func ensure<T>(_ work: @escaping (String) async throws -> T) async throws -> T {
            let token = try await getAccessToken()
            do {
                return try await work(token)
            } catch SomeError.tokenExpired {
                let refreshed = try await refreshAccessToken()
                return try await work(refreshed.accessToken)
            }
        }
        
        private func _checkErrno(_ errno: Int?) throws {
            guard let errno, errno != 0 else { return }
            if errno == 111 || errno == -6 { throw SomeError.tokenExpired }
            throw SomeError.api("API error: errno=\(errno)")
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
            try _checkErrno(meta.errno)
            guard let dlink = meta.list?.first?.dlink else { throw SomeError.fileNotFound(path) }
            
            // Step 2: download using dlink
            var dlURL = URLComponents(string: dlink)!
            dlURL.queryItems = (dlURL.queryItems ?? []) + [URLQueryItem(name: "access_token", value: accessToken)]
            var request = URLRequest(url: dlURL.url!)
            request.setValue("pan.baidu.com", forHTTPHeaderField: "User-Agent")
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                throw SomeError.api("Download failed: \(http.statusCode)")
            }
            return data
        }
        
        private func getFileId(path: String, accessToken: String) async throws -> Int64 {
            var components = URLComponents(string: "https://pan.baidu.com/rest/2.0/xpan/file")!
            components.queryItems = [
                URLQueryItem(name: "method", value: "list"),
                URLQueryItem(name: "access_token", value: accessToken),
                URLQueryItem(name: "dir", value: Constant.basePath),
            ]
            let (data, _) = try await URLSession.shared.data(from: components.url!)
            let resp = try JSONDecoder().decode(FileListResponse.self, from: data)
            try _checkErrno(resp.errno)
            let fileName = (path as NSString).lastPathComponent
            guard let file = resp.list?.first(where: { $0.server_filename == fileName }) else {
                throw SomeError.fileNotFound(path)
            }
            return file.fs_id
        }
        
        private func upload(
            path: String,
            data: Data,
            accessToken: String
        ) async throws {
            let baseURL = "https://pan.baidu.com/rest/2.0/xpan/file"
            
            // Baidu uses MD5 hashes in the block list.
            let blockList = "[\"\(data.md5Hex)\"]"
            
            // MARK: - Step 1: Precreate
            
            var preComponents = URLComponents(string: baseURL)!
            preComponents.queryItems = [
                URLQueryItem(name: "method", value: "precreate"),
                URLQueryItem(name: "access_token", value: accessToken)
            ]
            
            var preBody = URLComponents()
            preBody.queryItems = [
                URLQueryItem(name: "path", value: path),
                URLQueryItem(name: "size", value: "\(data.count)"),
                URLQueryItem(name: "isdir", value: "0"),
                URLQueryItem(name: "autoinit", value: "1"),
                URLQueryItem(name: "block_list", value: blockList),
                
                // 3 = overwrite existing file
                URLQueryItem(name: "rtype", value: "3")
            ]
            
            var preRequest = URLRequest(url: preComponents.url!)
            preRequest.httpMethod = "POST"
            preRequest.setValue(
                "application/x-www-form-urlencoded",
                forHTTPHeaderField: "Content-Type"
            )
            preRequest.httpBody = preBody.percentEncodedQuery?
                .data(using: .utf8)
            
            let (preData, preResponse) = try await URLSession.shared.data(
                for: preRequest
            )
            
            guard let preHTTPResponse = preResponse as? HTTPURLResponse,
                  (200..<300).contains(preHTTPResponse.statusCode) else {
                let statusCode = (preResponse as? HTTPURLResponse)?.statusCode ?? -1
                let responseBody = String(data: preData, encoding: .utf8) ?? ""
                
                throw SomeError.api(
                    "Precreate HTTP error: \(statusCode), \(responseBody)"
                )
            }
            
            let preResp = try JSONDecoder().decode(
                PrecreateResponse.self,
                from: preData
            )
            
            try _checkErrno(preResp.errno)
            
            guard let uploadId = preResp.uploadid else {
                throw SomeError.api(
                    "Precreate failed: \(String(data: preData, encoding: .utf8) ?? "")"
                )
            }
            
            // MARK: - Step 2: Upload slice
            
            var uploadComponents = URLComponents(
                string: "https://d.pcs.baidu.com/rest/2.0/pcs/superfile2"
            )!
            
            uploadComponents.queryItems = [
                URLQueryItem(name: "method", value: "upload"),
                URLQueryItem(name: "access_token", value: accessToken),
                URLQueryItem(name: "type", value: "tmpfile"),
                URLQueryItem(name: "path", value: path),
                URLQueryItem(name: "uploadid", value: uploadId),
                URLQueryItem(name: "partseq", value: "0")
            ]
            
            guard let uploadURL = uploadComponents.url else {
                throw SomeError.api("Failed to construct upload URL")
            }
            
            let boundary = "Boundary-\(UUID().uuidString)"
            
            var uploadRequest = URLRequest(url: uploadURL)
            uploadRequest.httpMethod = "POST"
            uploadRequest.setValue(
                "multipart/form-data; boundary=\(boundary)",
                forHTTPHeaderField: "Content-Type"
            )
            
            var body = Data()
            
            body.append(
                "--\(boundary)\r\n".data(using: .utf8)!
            )
            
            body.append(
                "Content-Disposition: form-data; name=\"file\"; filename=\"chunk\"\r\n"
                    .data(using: .utf8)!
            )
            
            body.append(
                "Content-Type: application/octet-stream\r\n\r\n"
                    .data(using: .utf8)!
            )
            
            body.append(data)
            
            body.append(
                "\r\n--\(boundary)--\r\n".data(using: .utf8)!
            )
            
            uploadRequest.httpBody = body
            
            let (uploadData, uploadResponse) = try await URLSession.shared.data(
                for: uploadRequest
            )
            
            guard let uploadHTTPResponse = uploadResponse as? HTTPURLResponse,
                  (200..<300).contains(uploadHTTPResponse.statusCode) else {
                let statusCode = (uploadResponse as? HTTPURLResponse)?.statusCode ?? -1
                let responseBody = String(data: uploadData, encoding: .utf8) ?? ""
                
                throw SomeError.api(
                    "Upload slice HTTP error: \(statusCode), \(responseBody)"
                )
            }
            
            // superfile2 normally returns JSON containing errno.
            if !uploadData.isEmpty,
               let uploadJSON = try? JSONSerialization.jsonObject(
                with: uploadData
               ) as? [String: Any],
               let errno = uploadJSON["errno"] as? Int {
                try _checkErrno(errno)
            }
            
            // MARK: - Step 3: Create / finalize
            
            var createComponents = URLComponents(string: baseURL)!
            createComponents.queryItems = [
                URLQueryItem(name: "method", value: "create"),
                URLQueryItem(name: "access_token", value: accessToken)
            ]
            
            var createBody = URLComponents()
            createBody.queryItems = [
                URLQueryItem(name: "path", value: path),
                URLQueryItem(name: "size", value: "\(data.count)"),
                URLQueryItem(name: "isdir", value: "0"),
                URLQueryItem(name: "uploadid", value: uploadId),
                URLQueryItem(name: "block_list", value: blockList),
                
                // 3 = overwrite existing file
                URLQueryItem(name: "rtype", value: "3")
            ]
            
            var createRequest = URLRequest(url: createComponents.url!)
            createRequest.httpMethod = "POST"
            createRequest.setValue(
                "application/x-www-form-urlencoded",
                forHTTPHeaderField: "Content-Type"
            )
            createRequest.httpBody = createBody.percentEncodedQuery?
                .data(using: .utf8)
            
            let (createData, createResponse) = try await URLSession.shared.data(
                for: createRequest
            )
            
            guard let createHTTPResponse = createResponse as? HTTPURLResponse,
                  (200..<300).contains(createHTTPResponse.statusCode) else {
                let statusCode = (createResponse as? HTTPURLResponse)?.statusCode ?? -1
                let responseBody = String(data: createData, encoding: .utf8) ?? ""
                
                throw SomeError.api(
                    "Create HTTP error: \(statusCode), \(responseBody)"
                )
            }
            
            let createResp = try JSONDecoder().decode(
                CreateResponse.self,
                from: createData
            )
            
            try _checkErrno(createResp.errno)
        }
        
        //        private func upload(path: String, data: Data, accessToken: String) async throws {
        //            // Step 1: precreate
        //            let blockList = "[\"\(data.md5Hex)\"]"
        //            var preBody = URLComponents()
        //            preBody.queryItems = [
        //                URLQueryItem(name: "path", value: path),
        //                URLQueryItem(name: "size", value: "\(data.count)"),
        //                URLQueryItem(name: "isdir", value: "0"),
        //                URLQueryItem(name: "autoinit", value: "1"),
        //                URLQueryItem(name: "block_list", value: blockList),
        //            ]
        //
        //            var preReq = URLRequest(url: URL(string: "https://pan.baidu.com/rest/2.0/xpan/file?method=precreate&access_token=\(accessToken)")!)
        //            preReq.httpMethod = "POST"
        //            preReq.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        //            preReq.httpBody = preBody.query?.data(using: .utf8)
        //            let (preData, _) = try await URLSession.shared.data(for: preReq)
        //            let preResp = try JSONDecoder().decode(PrecreateResponse.self, from: preData)
        //            try _checkErrno(preResp.errno)
        //            guard let uploadId = preResp.uploadid else {
        //                throw SomeError.api("Precreate failed: \(String(data: preData, encoding: .utf8) ?? "")")
        //            }
        //
        //            // Step 2: upload single slice
        //            let boundary = UUID().uuidString
        //            var uploadReq = URLRequest(url: URL(string: "https://d.pcs.baidu.com/rest/2.0/pcs/superfile2?method=upload&access_token=\(accessToken)&type=tmpfile&path=\(path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)&uploadid=\(uploadId)&partseq=0")!)
        //            uploadReq.httpMethod = "POST"
        //            uploadReq.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        //            var body = Data()
        //            body.append("--\(boundary)\r\nContent-Disposition: form-data; name=\"file\"; filename=\"chunk\"\r\nContent-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        //            body.append(data)
        //            body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        //            uploadReq.httpBody = body
        //            let (_, uploadResp) = try await URLSession.shared.data(for: uploadReq)
        //            if let http = uploadResp as? HTTPURLResponse, http.statusCode != 200 {
        //                throw SomeError.api("Upload slice failed: \(http.statusCode)")
        //            }
        //
        //            // Step 3: create (combine)
        //            var createBody = URLComponents()
        //            createBody.queryItems = [
        //                URLQueryItem(name: "path", value: path),
        //                URLQueryItem(name: "size", value: "\(data.count)"),
        //                URLQueryItem(name: "isdir", value: "0"),
        //                URLQueryItem(name: "uploadid", value: uploadId),
        //                URLQueryItem(name: "block_list", value: blockList),
        //            ]
        //            var createReq = URLRequest(url: URL(string: "https://pan.baidu.com/rest/2.0/xpan/file?method=create&access_token=\(accessToken)")!)
        //            createReq.httpMethod = "POST"
        //            createReq.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        //            createReq.httpBody = createBody.query?.data(using: .utf8)
        //            let (createData, _) = try await URLSession.shared.data(for: createReq)
        //            let createResp = try JSONDecoder().decode(CreateResponse.self, from: createData)
        //            try _checkErrno(createResp.errno)
        //        }
        
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
            let name1 = resp.netdisk_name ?? ""
            let name2 = resp.baidu_name
            return name1.isEmpty ? name2 : name1
        }
        
        func logout() {
            Keychain.delete()
            poltask?.cancel()
            poltask = nil
            Task { await checkAvailability() }
        }
        
        deinit {
            poltask?.cancel()
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
        let errno: Int?
        let list: [FileItem]?
    }
    
    private struct FileItem: Decodable {
        let fs_id: Int64
        let server_filename: String
    }
    
    private struct FileMetasResponse: Decodable {
        let errno: Int?
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
    enum SomeError: Error {
        case fileNotFound(String)
        case unauthenticated
        case authFailed
        case tokenExpired
        case tokenExchangeFailed(String)
        case api(Error)
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
