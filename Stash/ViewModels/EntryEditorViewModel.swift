//
//  CraftViewModel.swift
//  Stash
//
//  Created by Rayman on 2025/2/27.
//

import AppKit
import Combine
import Kingfisher

extension EntryEditorViewModel {
    enum Mode {
        case create(UUID?) // associated type - parent id if exists
        case update(UUID) // associated type - entry id
    }
}

@MainActor
class EntryEditorViewModel: ObservableObject {
    @Published var path: String?
    @Published var icon: Icon?
    @Published var title: String?
    @Published var savable = false
    @Published var parsable = false {
        didSet {
            savable = false
            title = nil
            icon = nil
        }
    }
    @Published var loading = false
    @Published var error: (any Error)?
    
    private var url: URL?
    private var cancellables = Set<AnyCancellable>()
    private var parseTask: Task<Void, Never>?
    
    let mode: Mode
    let cabinet: OkamuraCabinet
    let dominator: Dominator

    init(mode: Mode, cabinet: OkamuraCabinet, dominator: Dominator) {
        self.mode = mode
        self.cabinet = cabinet
        self.dominator = dominator
        
        bind()
        switch mode {
        case .create(let pid):
            break
        case .update(let eid):
            let entry = cabinet.storedEntries.filter({ $0.id == eid }).first
            // TODO: below line need to distinguish group and bookmark
            self.path = (entry as? Bookmark)?.url.absoluteString
            self.url = (entry as? Bookmark)?.url
            self.title = entry?.name
            self.icon = entry?.icon
            self.savable = true
        }
    }
    
    private func bind() {
        $path
            .compactMap({ $0 })
            .removeDuplicates()
            .map({ $0.count > 4 })
            .receive(on: RunLoop.main)
//            .dropFirst()
            .sink { [weak self] in self?.parsable = $0 }
            .store(in: &cancellables)
    }
    
    func parse() {
        parseTask?.cancel()
        parseTask = Task {
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

                try Task.checkCancellation()
                let _ = try await updateTitle(path)
                try Task.checkCancellation()
                async let _ = try updateImage(path)
                savable = true
            } catch is CancellationError {
                // superseded by a newer parse call, discard silently
            } catch {
                self.error = error
                ErrorTracker.shared.add(error)
            }
        }
    }
    
    func save() {
        guard savable else { return }
        do {
            switch mode {
            case .create(let pid):
                let b = Bookmark(id: UUID(), name: title!, parentId: pid, url: url!)
                
                if let pid = pid, let index = cabinet.storedEntries.firstIndex(where: { $0.id == pid }) {
                    cabinet.storedEntries.insert(b, at: index + 1)
                } else {
                    cabinet.storedEntries.insert(b, at: 0)
                }
                try cabinet.save()
                
            case .update(let eid):
                let b = Bookmark(id: eid, name: title!, url: url!)
                try cabinet.update(entry: b)
            }
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

