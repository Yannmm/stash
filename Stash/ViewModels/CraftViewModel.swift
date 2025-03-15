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
    init(entry: (any Entry)? = nil) {
        self.entry = entry
        guard entry != nil else { return }
        
        self.title = entry?.name
        switch entry {
        case let b as Bookmark:
            self.url = b.url
            Task {
                try await self.updateImage(url: b.url)
            }
            
        case let d as Directory:
            self.icon = NSImage(systemSymbolName: "folder", accessibilityDescription: nil)
            break
            
        default: break
        }
    }
    
    private var entry: (any Entry)?
    
    @Published var icon: NSImage?
    
    @Published var error: (any Error)?
    
    @Published var loading = false
    
    @Published var title: String?
    
    @Published var ableToSave = false
    
    var url: URL?
    
    private let dominator = Dominator()
    
    var cabinet: OkamuraCabinet!
    
    func parse(_ text: String) async throws {
        let normalized = normalizeUrl(text)
        guard let url = URL(string: normalized) else {
            throw CraftError.invalidUrl(text)
        }
        
        self.url = url
        
        loading = true
        defer {
            loading = false
            ableToSave = true
        }
        
         let _ = try await updateTitle(url: url)
        
        if let u = url.faviconUrl {
            async let _ = try updateImage(url: u)
        }
    }
    
    func save() {
        let b = Bookmark(id: UUID(), name: title!, url: url!)
        cabinet.upsert(entry: b)
        
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

