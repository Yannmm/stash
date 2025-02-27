//
//  CraftViewModel.swift
//  Stash
//
//  Created by Rayman on 2025/2/27.
//

import AppKit
import Kingfisher

@MainActor
class CraftViewModel: ObservableObject {
    @Published var icon: NSImage?
    
    @Published var error: (any Error)?
    
    @Published var loading = false
    
    @Published var title: String = ""
    
    private let dominator = Dominator()
    
    func parse(_ text: String) async throws {
        let normalized = normalizeUrl(text)
        guard let url = URL(string: normalized) else {
            throw CraftError.invalidUrl(text)
        }
        
        loading = true
        defer { loading = false }
        
         let _ = try await updateTitle(url: url)
        
        if let u = url.faviconUrl {
            async let _ = try updateImage(url: u)
        }
    }
    
    private func normalizeUrl(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if it already has a protocol
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return trimmed
        }
        
        // Check if it's a localhost or IP address
        if trimmed.hasPrefix("localhost") ||
           trimmed.range(of: "^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}", options: .regularExpression) != nil {
            return "http://" + trimmed
        }
        
        // Default to https for all other URLs
        return "https://" + trimmed
    }
    
    private func updateImage(url: URL) async throws {
        let image = try await withCheckedThrowingContinuation { continuation in
            KingfisherManager.shared.retrieveImage(with: url) { result in
                // Do something with `result`
                switch (result) {
                case .success(let r):
                    continuation.resume(returning: r.image)
                case .failure(let e):
                    continuation.resume(throwing: e)
                }
            }
        }
        
        icon = image
    }
    
    private func updateTitle(url: URL) async throws {
        let x = try await Dominator().fetchWebPageTitle(from: url)
        title = x
    }
    
    enum CraftError: Error {
        case invalidUrl(String)
    }
}

