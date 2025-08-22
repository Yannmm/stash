//
//  SearchViewModel.swift
//  Stash
//
//  Created by Yan Meng on 2025/7/15.
//

import Combine
import Foundation

class SearchViewModel: ObservableObject {
    @Published var items: [SearchItem] = []
    @Published var query = ""
    @Published var keyboardAction: KeyboardAction?
    @Published var index: Int?
    @Published var selectedBookmark: (any Entry)?
    
    private var cancellables = Set<AnyCancellable>()
    
    let _select = PassthroughSubject<SearchItem, Never>()
    
    func select(_ item: SearchItem) { _select.send(item) }
    
    let cabinet: OkamuraCabinet
    
    init(cabinet: OkamuraCabinet) {
        self.cabinet = cabinet
        
        bind()
    }
    
    private func bind() {
        let selectedEntry = _select.map({ [weak self] item in
            (self?.cabinet.storedEntries ?? []).first(where: { $0.id == item.id })
        })
            .compactMap({ $0 })
        
        selectedEntry
            .filter({ !$0.container })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.selectedBookmark = $0 }
            .store(in: &cancellables)
        
        // TOOD: 在 ui 上，如果group 有0个child，则灰色，无法选择
        let scoped = selectedEntry
            .filter({ $0.container })
            .withLatestFrom(Just(cabinet.storedEntries))
            .map({ $0.0.children(among: $0.1) })
        
        scoped
            .map({ _ in "" })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.query = $0 }
            .store(in: &cancellables)
        
        let _entries = CurrentValueSubject<[any Entry], Never>([])
        
        Publishers.Merge(cabinet.$storedEntries, scoped)
            .sink(receiveValue: _entries.send)
            .store(in: &cancellables)
        
        let seachItems = PassthroughSubject<[SearchItem], Never>()
        
        _entries.map({ event in
            event.map({ e in
                var type: EntryType!
                var detail: String!
                switch e {
                case let g as Group:
                    type = .directory
                    let children =  g.children(among: event)
                    detail = "\(children.count) item(s)"
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
        .sink(receiveValue: seachItems.send)
        .store(in: &cancellables)
        
        Publishers.CombineLatest(seachItems, $query.map({ $0.lowercased() }))
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
        
        $items.map({ $0.count })
            .removeDuplicates()
            .map({ $0 > 0 ? 0 : nil })
            .sink { [weak self] in
                self?.index = $0
            }
            .store(in: &cancellables)
        
        $keyboardAction.withLatestFrom2($index.compactMap({ $0 }), $items)
            .map({ t3 in
                switch t3.0 {
                case .down: // ↓ Down arrow
                    return (t3.1 + 1) % t3.2.count
                case .up: // ↑ Up arrow
                    return (t3.1 - 1 + t3.2.count) % t3.2.count
                default: return nil
                }
            })
            .compactMap({ $0 })
            .sink { [weak self] in
                self?.index = $0
            }
            .store(in: &cancellables)
        
        $keyboardAction.filter({ $0 == .enter })
            .withLatestFrom2($index.compactMap({ $0 }), $items)
            .map({ $0.2[$0.1] })
            .sink { [weak self] in
                self?.select($0)
            }
            .store(in: &cancellables)
        
    }
}


extension Publisher {
    func withLatestFrom<P>(
        _ other: P
    ) -> AnyPublisher<(Self.Output, P.Output), Failure> where P: Publisher, Self.Failure == P.Failure {
        let other = other
        // Note: Do not use `.map(Optional.some)` and `.prepend(nil)`.
        // There is a bug in iOS versions prior 14.5 in `.combineLatest`. If P.Output itself is Optional.
        // In this case prepended `Optional.some(nil)` will become just `nil` after `combineLatest`.
            .map { (value: $0, ()) }
            .prepend((value: nil, ()))
        
        return map { (value: $0, token: UUID()) }
            .combineLatest(other)
            .removeDuplicates(by: { (old, new) in
                let lhs = old.0, rhs = new.0
                return lhs.token == rhs.token
            })
            .map { ($0.value, $1.value) }
            .compactMap { (left, right) in
                right.map { (left, $0) }
            }
            .eraseToAnyPublisher()
    }
    
    
    func withLatestFrom2<P1, P2>(
        _ p1: P1,
        _ p2: P2
    ) -> AnyPublisher<(Self.Output, P1.Output, P2.Output), Failure>
    where P1: Publisher, P2: Publisher,
          Self.Failure == P1.Failure,
          Self.Failure == P2.Failure
    {
        // Workaround to avoid iOS <14.5 Optional combineLatest bug
        let latestP1 = p1
            .map { (value: $0, ()) }
            .prepend((value: nil, ()))
        
        let latestP2 = p2
            .map { (value: $0, ()) }
            .prepend((value: nil, ()))
        
        // Combine p1 and p2 first
        let combinedLatest = latestP1.combineLatest(latestP2)
        
        return self
            .map { (value: $0, token: UUID()) }
            .combineLatest(combinedLatest)
            .removeDuplicates(by: { $0.0.token == $1.0.token })
            .map { (left, right) in
                (left.value, right.0.value, right.1.value)
            }
            .compactMap { trigger, l1, l2 in
                if let l1 = l1, let l2 = l2 {
                    return (trigger, l1, l2)
                } else {
                    return nil
                }
            }
            .eraseToAnyPublisher()
    }
    
}
