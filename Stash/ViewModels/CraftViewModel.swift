//
//  CraftViewModel.swift
//  Stash
//
//  Created by Rayman on 2025/2/27.
//

import AppKit
import Combine
import Kingfisher

@MainActor
class CraftViewModel: ObservableObject {
    @Published var icon: Icon?
    @Published var error: (any Error)?
    @Published var loading = false
    @Published var title: String?
    @Published var savable = false
    @Published var parsable = false {
        didSet {
            savable = false
            title = nil
            icon = nil
        }
    }
    @Published var path: String?
    private var url: URL?
    var anchorId: UUID?
    
    private var cancellables = Set<AnyCancellable>()
    
    private let dominator = Dominator()
    
    var cabinet: OkamuraCabinet!
    
    private var entry: (any Entry)?
    
    init(entry: (any Entry)? = nil) {
        self.entry = entry
        bind()
        guard entry != nil else { return }
        
        self.title = entry?.name
        self.icon = entry?.icon
    }
    
    private func bind() {
        $path
            .compactMap({ $0 })
            .removeDuplicates()
            .map({ $0.count > 4 })
            .sink { [weak self] in self?.parsable = $0 }
            .store(in: &cancellables)
    }
    
    func parse() async {
        loading = true
        defer {
            loading = false
        }
        do {
            guard let p = path, !p.isEmpty else {
                throw CraftError.emptyPath
            }
            
            let path = Path(p)
            
            switch path {
            case .file(let url):
                self.url = url
            case .web(let url):
                self.url = url
            case .vnc(let url):
                self.url = url
            case .whatever(let url):
                self.url = url
            }
            
            let _ = try await updateTitle(path)
            async let _ = try updateImage(path)
            savable = true
        } catch {
            self.error = error
            ErrorTracker.shared.add(error)
        }
    }
    
    func save() {
        do {
            let b = Bookmark(id: UUID(), name: title!, url: url!)
            try cabinet.relocate(entry: b, anchorId: anchorId)
        } catch {
            self.error = error
            ErrorTracker.shared.add(error)
        }
    }
    
    
    
    private func updateImage(_ path: Path) async throws {
        switch path {
        case .file(let url):
            icon = .local(url)
        case .vnc(_):
            icon = .system("square.on.square.intersection.dashed")
        case .web(let url):
            if let furl = url.faviconUrl {
                icon =  .favicon(furl)
            } else {
                icon = .system("globe")
            }
        case .whatever:
            icon = .system("link")
        }
    }
    
    private func updateTitle(_ path: Path) async throws {
        switch path {
        case .file(let url):
            title = url.lastPathComponent
        case .web(let url):
            do {
                title = try await Dominator().fetchWebPageTitle(from: url)
            } catch {
                title = url.absoluteString
                ErrorTracker.shared.add(error)
            }
        case .vnc(let url):
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.scheme = nil
            title = components?.string?.replacingOccurrences(of: "//", with: "") ?? url.absoluteString
        case .whatever(let url):
            title = url.absoluteString
        }
    }
    
    enum CraftError: Error {
        case emptyPath
        case invalidUrl(String)
        case unsupportedUrl(String)
    }
}

