//
//  SearchViewModel.swift
//  Stash
//
//  Created by Yan Meng on 2025/7/15.
//

import Combine

class SearchViewModel: ObservableObject {
    @Published var searching = false
    @Published var items: [SearchItem] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    let cabinet: OkamuraCabinet
    
    init(cabinet: OkamuraCabinet) {
        self.cabinet = cabinet
        
        bind()
    }
    
    private func bind() {
        cabinet.$storedEntries.map({ event in
            event.map({ e in
                var type: EntryType!
                var detail: String!
                switch e {
                case let g as Group:
                    type = .directory
                    let children =  g.children(among: event)
                    detail = "\(children.count)"
                case let b as Bookmark:
                    type = .bookmark
                    detail = b.url.absoluteString
                default:
                    // Impossible to reach
                    fatalError()
                }
                let item = SearchItem(id: e.id, title: e.name, detail: detail, icon: e.icon, type: type)
                return item
            })
        })
        .sink { [weak self] in
            self?.items = $0
        }
        .store(in: &cancellables)
    }
}
