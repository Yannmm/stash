//
//  SearchViewModel.swift
//  Stash
//
//  Created by Yan Meng on 2025/7/15.
//

import Combine
import Foundation
import CombineExt

extension SearchViewModel {
    enum Depth: Equatable {
        case root
        case group(String)
        
        static func ==(lhs: Depth, rhs: Depth) -> Bool {
            switch (lhs, rhs) {
            case let (.group(a), .group(b)):
                return a == b
            case (.root, .root):
                return true
            default:
                return false
            }
        }
    }
}

class SearchViewModel: ObservableObject {
    @Published var items: [SearchItem] = []
    @Published var query = ""
    @Published var keyboardAction: KeyboardAction?
    @Published var index: Int?
    @Published var depth: Depth = .root
    
    let _bookmark = PassthroughSubject<Bookmark, Never>()
    
    var bookmark: AnyPublisher<Bookmark, Never> { _bookmark.eraseToAnyPublisher() }
    
    private var cancellables = Set<AnyCancellable>()
    
    let _select = PassthroughSubject<SearchItem, Never>()
    
    func select(_ item: SearchItem) { _select.send(item) }
    
    let cabinet: OkamuraCabinet
    
    init(cabinet: OkamuraCabinet) {
        self.cabinet = cabinet
        bind()
    }
    
    private func bind() {
        
        // nil means root
        let current_entry = CurrentValueSubject<(any Entry)?, Never>(nil)
        
        _select
            .filter({ !$0.isBack })
            .map({ [weak self] item in
                (self?.cabinet.storedEntries ?? []).first(where: { $0.id == item.id })
            })
            .sink(receiveValue: current_entry.send)
            .store(in: &cancellables)
        
        // For back only
        let parent1 = _select.filter({ $0.isBack })
            .withLatestFrom(current_entry, resultSelector: { a, b in b?.parentId })
            .withLatestFrom(Just(cabinet.storedEntries), resultSelector: { a, b in a == nil ? nil : b.findBy(id: a!) })
        
        // For back, parent become current
        parent1.sink(receiveValue: current_entry.send)
            .store(in: &cancellables)
        
        // If selected item is bookmark, then that's it
        current_entry
            .compactMap({ $0 as? Bookmark })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?._bookmark.send($0) }
            .store(in: &cancellables)
        
        // If it's container
        current_entry
            .compactMap({ $0 })
            .filter({ $0.container })
            .map({ Depth.group($0.name) })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.depth = $0 }
            .store(in: &cancellables)
        
        
        // If current become nil, it means we are back to root
        current_entry
            .filter({ $0 == nil })
            .dropFirst()
            .sink { [weak self] _ in self?.depth = .root }
            .store(in: &cancellables)
        
        // TODO: 在 ui 上，如果group 有0个child，则灰色，无法选择
        let children2 = current_entry
            .filter({ $0 == nil || $0!.container })
            .withLatestFrom(Just(cabinet.storedEntries), resultSelector: {($0, $1)})
            .map({ $0.0 == nil ? $0.1 : $0.0!.children(among: $0.1) })
        
        children2
            .map({ _ in "" })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.query = $0 }
            .store(in: &cancellables)
        
        
        // Scope
        let entries = CurrentValueSubject<[any Entry], Never>([])
        
        Publishers.Merge(
            cabinet.$storedEntries
                .withLatestFrom($depth.filter({ $0 == .root }), resultSelector: { ($0, $1) })
                .map({ $0.0 }),
            children2,
        )
        .sink(receiveValue: entries.send)
        .store(in: &cancellables)
        
        let seachItems = CurrentValueSubject<[SearchItem], Never>([])
        
        entries
            .withLatestFrom(Just(cabinet.storedEntries), resultSelector: { ($0, $1) })
            .map({ event in
                event.0.map({ e in
                    var detail: String!
                    switch e {
                    case let g as Group:
                        let children =  g.children(among: event.1)
                        detail = "\(children.count) item(s)"
                    case let b as Bookmark:
                        detail = b.url.absoluteString
                    default:
                        // Impossible to reach
                        fatalError()
                    }
                    let item = SearchItem(id: e.id, title: e.name, detail: detail, icon: e.icon)
                    return item
                })
            })
            .sink(receiveValue: seachItems.send)
            .store(in: &cancellables)
        
        
        let parent2 = current_entry
            .map({ $0?.parentId })
            .withLatestFrom(Just(cabinet.storedEntries), resultSelector: {($0, $1)})
            .map({ event in event.0 == nil ? nil : event.1.first(where: { event.0 == $0.id }) })
        
        Publishers.CombineLatest3(seachItems, $query.map({ $0.lowercased() }), $depth)
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .withLatestFrom(parent2, resultSelector: {($0, $1)})
            .map({ event in
                var items = event.0.0
                let keyword = event.0.1
                let depth = event.0.2
                let parent = event.1
                
                var isRoot: Bool!
                var back: String!
                switch depth {
                case .root:
                    isRoot = true
                case .group(_):
                    isRoot = false
                    back = "\"\(parent?.name ?? "Root")\""
                }
                if isRoot && keyword.count < 2 { return [] }
                items = items.filter({ keyword.isEmpty ? true : ($0.title.lowercased().contains(keyword) || $0.detail.lowercased().contains(keyword)) })
                if !isRoot {
                    items.insert(SearchItem.back(title: "Back to", detail: back), at: 0)
                }
                return items
            })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.items = $0
            }
            .store(in: &cancellables)
        
        $items.map({ $0.count })
            .removeDuplicates()
            .map({ $0 > 0 ? 0 : nil })
            .sink { [weak self] in
                self?.index = $0
            }
            .store(in: &cancellables)
        
        $keyboardAction.withLatestFrom2($index, $items)
            .map({ t3 in
                guard let index = t3.1 else { return nil }
                switch t3.0 {
                case .down: // ↓ Down arrow
                    return (index + 1) % t3.2.count
                case .up: // ↑ Up arrow
                    return (index - 1 + t3.2.count) % t3.2.count
                default: return nil
                }
            })
            .compactMap({ $0 })
            .sink { [weak self] in
                self?.index = $0
            }
            .store(in: &cancellables)
        
        $keyboardAction.filter({ $0 == .enter })
            .withLatestFrom2($index, $items)
            .map({ $0.1 == nil ? nil : $0.2[$0.1!] })
            .compactMap({ $0 })
            .sink { [weak self] in
                self?.select($0)
            }
            .store(in: &cancellables)
        
    }
}
