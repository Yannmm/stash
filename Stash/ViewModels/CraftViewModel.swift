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
    @Published var icon: NSImage! = NSImage(systemSymbolName: "link", accessibilityDescription: nil)
    
    @Published var error: (any Error)?
    
    @Published var loading = false
    
    @Published var title: String?
    
    private let dominator = Dominator()
    
    func parse(_ text: String) async throws {
        guard let url = URL(string: text) else {
            throw CraftError.invalidUrl(text)
        }
        
        loading = true
        defer { loading = false }
        
        async let _ = try updateTitle(url: url)
        
        if let u = url.faviconUrl {
            async let _ = try updateImage(url: u)
        }
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
        title = try await dominator.fetchWebPageTitle(from: url)
    }
    
    enum CraftError: Error {
        case invalidUrl(String)
    }
}

