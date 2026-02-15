//
//  CraftViewModel.swift
//  Stash
//
//  Created by Rayman on 2025/2/27.
//

import AppKit
import Combine
import Kingfisher

class EntryEditorViewModel: ObservableObject {
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
    private var cancellables = Set<AnyCancellable>()
    
    let cabinet: OkamuraCabinet
    let dominator: Dominator
    var entryId: UUID?
    var parentId: UUID?

    init(cabinet: OkamuraCabinet, dominator: Dominator, entryId: UUID?, parentId: UUID?) {
        self.entryId = entryId
        self.parentId = parentId
        self.cabinet = cabinet
        self.dominator = dominator
        
        bind()
        guard let id = entryId,
              let entry = cabinet.storedEntries.filter({ $0.id == id }).first else { return }
        
        self.title = entry.name
        self.icon = entry.icon
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
//            try cabinet.relocate(entry: b, anchorId: anchorId)
            try cabinet.relocate(entry: b, anchorId: nil)
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

