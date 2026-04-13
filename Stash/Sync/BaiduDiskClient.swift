//
//  BaiduDiskClient.swift
//  Stash
//
//  Created by Cursor on 2026/4/13.
//

import Foundation
import CryptoKit

struct BaiduOAuthToken: Codable, Equatable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: TimeInterval
    let scope: String?
    let tokenType: String?
    let createdAt: Date

    var expirationDate: Date {
        createdAt.addingTimeInterval(expiresIn)
    }

    var isExpired: Bool {
        expirationDate <= Date().addingTimeInterval(60)
    }
}

final class BaiduDiskClient {
    struct FileInfo: Decodable, Equatable {
        let fsID: Int64?
        let path: String
        let serverFilename: String
        let size: Int?
        let md5: String?
        let serverMtime: TimeInterval?

        enum CodingKeys: String, CodingKey {
            case fsID = "fs_id"
            case path
            case serverFilename = "server_filename"
            case size
            case md5
            case serverMtime = "server_mtime"
        }
    }

    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    func authorizationURL(clientID: String, redirectURI: String, state: String, scope: String = "netdisk") throws -> URL {
        var components = URLComponents(string: "https://openapi.baidu.com/oauth/2.0/authorize")
        components?.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "scope", value: scope)
        ]
        guard let url = components?.url else {
            throw BaiduDiskError.invalidAuthorizationURL
        }
        return url
    }

    func exchangeCode(clientID: String, clientSecret: String, code: String, redirectURI: String) async throws -> BaiduOAuthToken {
        let response: OAuthTokenResponse = try await formRequest(
            url: URL(string: "https://openapi.baidu.com/oauth/2.0/token")!,
            parameters: [
                "grant_type": "authorization_code",
                "code": code,
                "client_id": clientID,
                "client_secret": clientSecret,
                "redirect_uri": redirectURI
            ]
        )

        return BaiduOAuthToken(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresIn: response.expiresIn,
            scope: response.scope,
            tokenType: response.tokenType,
            createdAt: Date()
        )
    }

    func refreshToken(clientID: String, clientSecret: String, refreshToken: String) async throws -> BaiduOAuthToken {
        let response: OAuthTokenResponse = try await formRequest(
            url: URL(string: "https://openapi.baidu.com/oauth/2.0/token")!,
            parameters: [
                "grant_type": "refresh_token",
                "refresh_token": refreshToken,
                "client_id": clientID,
                "client_secret": clientSecret
            ]
        )

        return BaiduOAuthToken(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresIn: response.expiresIn,
            scope: response.scope,
            tokenType: response.tokenType,
            createdAt: Date()
        )
    }

    func listFiles(in directory: String, accessToken: String) async throws -> [FileInfo] {
        var components = URLComponents(string: "https://pan.baidu.com/rest/2.0/xpan/file")!
        components.queryItems = [
            URLQueryItem(name: "method", value: "list"),
            URLQueryItem(name: "dir", value: directory),
            URLQueryItem(name: "access_token", value: accessToken)
        ]

        let response: FileListResponse = try await request(url: try components.unwrapURL())
        return response.list
    }

    func file(named name: String, in directory: String, accessToken: String) async throws -> FileInfo? {
        let files = try await listFiles(in: directory, accessToken: accessToken)
        return files.first(where: { $0.serverFilename == name })
    }

    func downloadFile(fsID: Int64, accessToken: String) async throws -> Data {
        let dlink = try await downloadLink(for: fsID, accessToken: accessToken)
        var request = URLRequest(url: dlink)
        request.setValue("pan.baidu.com", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
        return data
    }

    func uploadFile(data: Data, path: String, accessToken: String) async throws -> FileInfo {
        let md5 = Insecure.MD5.hash(data: data).map { String(format: "%02x", $0) }.joined()
        let blockList = "[\"\(md5)\"]"

        let precreate: PrecreateResponse = try await formRequest(
            url: URL(string: "https://pan.baidu.com/rest/2.0/xpan/file")!,
            parameters: [
                "method": "precreate",
                "access_token": accessToken,
                "path": path,
                "size": "\(data.count)",
                "isdir": "0",
                "autoinit": "1",
                "block_list": blockList
            ]
        )

        try await uploadTemporaryChunk(
            data: data,
            path: path,
            accessToken: accessToken,
            uploadID: precreate.uploadID
        )

        let _: CreateResponse = try await formRequest(
            url: URL(string: "https://pan.baidu.com/rest/2.0/xpan/file")!,
            parameters: [
                "method": "create",
                "access_token": accessToken,
                "path": path,
                "size": "\(data.count)",
                "isdir": "0",
                "uploadid": precreate.uploadID,
                "block_list": blockList
            ]
        )

        guard let directory = path.split(separator: "/").dropLast().joined(separator: "/").nilIfEmpty else {
            throw BaiduDiskError.invalidRemotePath
        }
        guard let filename = path.split(separator: "/").last.map(String.init) else {
            throw BaiduDiskError.invalidRemotePath
        }
        return try await file(named: filename, in: "/\(directory)", accessToken: accessToken) ??
            FileInfo(fsID: nil, path: path, serverFilename: filename, size: data.count, md5: md5, serverMtime: Date().timeIntervalSince1970)
    }

    private func downloadLink(for fsID: Int64, accessToken: String) async throws -> URL {
        var components = URLComponents(string: "https://pan.baidu.com/rest/2.0/xpan/multimedia")!
        components.queryItems = [
            URLQueryItem(name: "method", value: "filemetas"),
            URLQueryItem(name: "access_token", value: accessToken),
            URLQueryItem(name: "fsids", value: "[\(fsID)]"),
            URLQueryItem(name: "dlink", value: "1")
        ]

        let response: FileMetasResponse = try await request(url: try components.unwrapURL())
        guard let raw = response.list.first?.dlink,
              let url = URL(string: raw) else {
            throw BaiduDiskError.missingDownloadLink
        }
        return url
    }

    private func uploadTemporaryChunk(data: Data, path: String, accessToken: String, uploadID: String) async throws {
        var components = URLComponents(string: "https://d.pcs.baidu.com/rest/2.0/pcs/superfile2")!
        components.queryItems = [
            URLQueryItem(name: "method", value: "upload"),
            URLQueryItem(name: "access_token", value: accessToken),
            URLQueryItem(name: "type", value: "tmpfile"),
            URLQueryItem(name: "path", value: path),
            URLQueryItem(name: "uploadid", value: uploadID),
            URLQueryItem(name: "partseq", value: "0")
        ]

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: try components.unwrapURL())
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = multipartBody(boundary: boundary, name: "file", filename: "chunk", mimeType: "application/octet-stream", data: data)

        let (responseData, response) = try await session.data(for: request)
        try validate(response: response, data: responseData)
    }

    private func request<T: Decodable>(url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)
        try validate(response: response, data: data)
        return try decode(T.self, from: data)
    }

    private func formRequest<T: Decodable>(url: URL, parameters: [String: String]) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = parameters
            .map { key, value in
                "\(key)=\(value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value)"
            }
            .sorted()
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
        return try decode(T.self, from: data)
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data),
               let message = errorResponse.errorDescription ?? errorResponse.errorMsg {
                throw BaiduDiskError.apiError(message)
            }
            throw error
        }
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data),
               let message = errorResponse.errorDescription ?? errorResponse.errorMsg {
                throw BaiduDiskError.apiError(message)
            }
            throw BaiduDiskError.httpError(http.statusCode)
        }
    }

    private func multipartBody(boundary: String, name: String, filename: String, mimeType: String, data: Data) -> Data {
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }
}

extension BaiduDiskClient {
    enum BaiduDiskError: LocalizedError {
        case invalidAuthorizationURL
        case missingDownloadLink
        case invalidRemotePath
        case apiError(String)
        case httpError(Int)

        var errorDescription: String? {
            switch self {
            case .invalidAuthorizationURL:
                return "Failed to build the Baidu authorization URL."
            case .missingDownloadLink:
                return "Baidu did not return a download link for the requested file."
            case .invalidRemotePath:
                return "The configured Baidu remote path is invalid."
            case .apiError(let message):
                return message
            case .httpError(let code):
                return "Baidu API request failed with HTTP \(code)."
            }
        }
    }

    private struct OAuthTokenResponse: Decodable {
        let accessToken: String
        let refreshToken: String
        let expiresIn: TimeInterval
        let scope: String?
        let tokenType: String?
    }

    private struct FileListResponse: Decodable {
        let list: [FileInfo]
    }

    private struct FileMetaItem: Decodable {
        let dlink: String?
    }

    private struct FileMetasResponse: Decodable {
        let list: [FileMetaItem]
    }

    private struct PrecreateResponse: Decodable {
        let uploadID: String

        enum CodingKeys: String, CodingKey {
            case uploadID = "uploadid"
        }
    }

    private struct CreateResponse: Decodable {
        let fsID: Int64?

        enum CodingKeys: String, CodingKey {
            case fsID = "fs_id"
        }
    }

    private struct APIErrorResponse: Decodable {
        let error: String?
        let errorDescription: String?
        let errorMsg: String?

        enum CodingKeys: String, CodingKey {
            case error
            case errorDescription = "error_description"
            case errorMsg = "error_msg"
        }
    }
}

private extension URLComponents {
    func unwrapURL() throws -> URL {
        guard let url else {
            throw BaiduDiskClient.BaiduDiskError.invalidAuthorizationURL
        }
        return url
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
