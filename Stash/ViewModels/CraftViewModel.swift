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
//            Task {
//                try await self.updateImage(url: b.url)
//            }
            
        case let d as Group:
            self.icon = NSImage(systemSymbolName: "square.stack.3d.down.right.fill", accessibilityDescription: nil)
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
    
    var anchorId: UUID?
    
    private let dominator = Dominator()
    
    var cabinet: OkamuraCabinet!
    
    func parse(_ text: String) async throws {
        let path = Path(text)
        
        switch path {
        case .file(let url):
            self.url = url
        case .web(let url):
            self.url = url
        case .unknown:
            return
        }
        
        loading = true
        defer {
            loading = false
            ableToSave = true
        }
        
        let _ = try await updateTitle(path)
        
        async let _ = try updateImage(path)
    }
    
    func save() {
        let b = Bookmark(id: UUID(), name: title!, url: url!)
        cabinet.relocate(entry: b, anchorId: anchorId)
    }
    

    
    private func updateImage(_ path: Path) async throws {
        switch path {
        case .file(let url):
            let i = NSWorkspace.shared.icon(forFile: url.path)
            i.size = CGSize(width: 16, height: 16)
            icon = i
        case .web(let url):
            if let u = url.faviconUrl {
                let image = try await withCheckedThrowingContinuation { continuation in
                    KingfisherManager.shared.retrieveImage(with: u) { result in
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
            } else {
                icon = NSImage(systemSymbolName: "link", accessibilityDescription: nil)
            }
        case .unknown:
            return
        }
    }
    
    private func updateTitle(_ path: Path) async throws {
        switch path {
        case .file(let url):
            title = url.lastPathComponent
        case .web(let url):
            title = try await Dominator().fetchWebPageTitle(from: url)
        case .unknown:
            return
        }
    }
    
    enum CraftError: Error {
        case invalidUrl(String)
    }
}

