//
//  FaviconLoader.swift
//  Stash
//
//  Created by Rayman on 2025/2/19.
//

import AppKit

class FaviconLoader {
    
    static func loadImage(from url: URL, timeout: TimeInterval = 10.0) async throws -> NSImage? {
        guard let host = url.host(), let iconUrl = URL(string: String(format: Constant.template, host)) else {
            throw URLError(.badURL)
        }
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
        let session = URLSession(configuration: configuration)
        
        let (data, _) = try await session.data(from: iconUrl)
        return NSImage(data: data)
    }
    
    struct Constant {
        static let template = "http://icons.duckduckgo.com/ip2/%@.ico"
    }
}

//Task {
//    do {
//        let image = try await ImageLoader.loadImage(from: "https://example.com/image.png", timeout: 10.0)
//        // Use the image
//    } catch {
//        print("Error loading image: \(error)")
//    }
//}
