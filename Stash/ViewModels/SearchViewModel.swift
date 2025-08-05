//
//  SearchViewModel.swift
//  Stash
//
//  Created by Yan Meng on 2025/7/15.
//

import Combine
import Foundation

class SearchViewModel: ObservableObject {
    @Published var searching = false
    @Published var items: [SearchItem] = []
    @Published private var originalItems: [SearchItem] = []
    @Published var searchText = ""
    @Published var keyboardAction: KeyboardAction?
    
    private var cancellables = Set<AnyCancellable>()
    
//    let _keyboard = PassthroughSubject<KeyboardAction?, Never>()
//    var keyboard: AnyPublisher<KeyboardAction?, Never> { _keyboard.eraseToAnyPublisher() }
//    func setKeyboard(_ value: KeyboardAction?) {
//        _keyboard.send(value)
//    }
    
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
            self?.originalItems = $0
        }
        .store(in: &cancellables)
        
        Publishers.CombineLatest($originalItems, $searchText.map({ $0.lowercased() }))
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .map({ items, keyword in
                guard keyword.count >= 2 else { return [] }
                return items.filter({ $0.title.lowercased().contains(keyword) || $0.detail.lowercased().contains(keyword) })
            })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.items = $0
            }
            .store(in: &cancellables)
    }
}
