//
//  xxx.swift
//  Stash
//
//  Created by Rayman on 2026/1/12.
//

import Combine
import Foundation
import SwiftUI

class WorkbenchViewModel: ObservableObject, CascadeJudge {
    @Published var search = "" {
        didSet {
            if search.count > 0 {
                hierarchy = .descendant
            }
        }
    }
    @Published var hierarchy: Hierarchy = .descendant
    @Published private(set) var rows: [Row] = []
    @Published var hashtagFilter: String? {
        didSet {
            if let f = hashtagFilter, f.count > 0 {
                hierarchy = .descendant
            }
        }
    }
    var hashtags: [String] {
        let set = Set(housekeeper.storedEntries
            .map({ $0.hashtags })
            .compactMap({ $0 })
            .flatMap({ $0 }))
            .sorted()
        return Array(set)
    }
    @Published var error: Error?
    @Published private(set) var selectedGroup: Group?
    
    private var _cancellables = Set<AnyCancellable>()
    fileprivate var indentColorStorage = [Color]()
    
    var entries: [any Entry] { housekeeper.storedEntries }
    
    func update(_ entries: [any Entry]) {
        housekeeper.storedEntries = entries
        do {
            try housekeeper.save()
        } catch {
            self.error = error
        }
    }
    
    let housekeeper: Housekeeper
    let wrapper: GroupSelectionWrapper
    
    init(housekeeper: Housekeeper, wrapper: GroupSelectionWrapper) {
        self.wrapper = wrapper
        self.housekeeper = housekeeper
        _bind()
    }
    
    private func _bind() {
        wrapper.$selection
            .map({ id in self.housekeeper.storedEntries.first(where: { $0.id == id }) as? Group })
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] in self?.selectedGroup = $0 })
            .store(in: &_cancellables)
        
        Publishers.CombineLatest4(
            wrapper.$selection,
            housekeeper.$storedEntries,
            $hierarchy.removeDuplicates(),
            Publishers.CombineLatest($search.map({ $0.trim() }).removeDuplicates(), $hashtagFilter)
        )
        .map { [unowned self] a, b, c, d in
            let hashtag = d.1
            let query = d.0
            let result = self.heirs(b, a, c)
                .map {
                    let tags = $0.hashtags ?? []
                    if let htf = hashtag,
                       htf.count > 0,
                       !tags.contains(htf) {
                        return Optional<Row>.none
                    }
                    let info = _info(query, $0, b, c)
                    if query.count > 0 {
                        guard
                            $0.name.range(of: query, options: .caseInsensitive) != nil ||
                                ($0.hashtags ?? []).contains(where: { $0.range(of: query, options: .caseInsensitive) != nil }) ||
                                info.3
                        else {
                            return Optional<Row>.none
                        }
                    }
                    
                    return Row(id: $0.id,
                               icon: $0.icon,
                               title: $0.name,
                               description: info.0,
                               trail: trail(query, $0, b, a),
                               tags: Array(tags),
                               expanded: info.2,
                               expandable: $0.container,
                               extra: info.1,
                               actionable: $0 is Actionable,
                               entryType: info.4)
                }
                .compactMap({ $0 })
            return result
        }
        .receive(on: DispatchQueue.main)
        .sink(receiveValue: { [weak self] in self?.rows = $0 })
        .store(in: &_cancellables)
        
        $hierarchy
            .removeDuplicates()
            .map { _ in [] }
            .sink(receiveValue: { [weak self] in self?.indentColorStorage = $0 })
            .store(in: &_cancellables)
    }
    
    var title: String {
        selectedGroup?.title ?? "All Bookmarks"
    }
    
    var bookmarkCount: Int {
        if let c = selectedGroup {
            return _bookmarks(c.relatedEntries(housekeeper.storedEntries)).count
        } else {
            return _bookmarks(housekeeper.storedEntries).count
        }
    }
    
    var groupCount: Int {
        if let c = selectedGroup {
            return _groups(c.relatedEntries(housekeeper.storedEntries)).count
        } else {
            return _groups(housekeeper.storedEntries).count
        }
    }
    
    func open(_ id: UUID) {
        guard let b = entries.findBy(id: id) as? Bookmark else { return }
        do {
            b.open()
            try housekeeper.asRecent(b)
        } catch {
            self.error = error
        }
    }
    
    func delete(_ id: UUID) {
        guard let entry = entries.findBy(id: id) else { return }
        do {
            try housekeeper.delete(entry: entry)
        } catch {
            self.error = error
        }
    }
    
    func ungroup(_ id: UUID) {
        guard let entry = entries.findBy(id: id) else { return }
        do {
            try housekeeper.ungroup(entry: entry)
        } catch {
            self.error = error
        }
    }
    
    private func heirs(_ entries: [any Entry], _ selection: UUID?, _ hierarchy: Hierarchy) -> [any Entry] {
        let group = housekeeper.storedEntries.first(where: { $0.id == selection }) as? Group
        switch hierarchy {
        case .child:
            // TODO: selection maybe hashtag as well
            return group.children(among: entries)
        case .descendant:
            return group.descendants(among: entries)
        }
    }
    
    private func _groups(_ entries: [any Entry]) -> [Group] {
        entries.compactMap({ $0 as? Group })
    }
    
    private func _bookmarks(_ entries: [any Entry]) -> [Bookmark] {
        entries.compactMap({ $0 as? Bookmark })
    }
    
    private func trail(_ query: String, _ target: any Entry, _ entries: [any Entry], _ selectionId: UUID?) -> [Group] {
        var trail = [Group]()
        guard query.count <= 0 else {
            return trail
        }
        var pid = target.parentId
        while pid != nil {
            let group = entries.filter({ $0.id == pid }).compactMap({ $0 as? Group }).first
            if (pid == selectionId) {
                break
            }
            if let g = group  {
                trail.append(g)
            }
            pid = group?.parentId
        }
        return trail
    }
    
    private func _info(_ query: String, _ entry: any Entry, _ entries: [any Entry], _ hierarchy: Hierarchy) -> (String, String?, Bool, Bool, EntryType) {
        switch entry {
        case let b as Bookmark:
            let path = query.count > 0 ? b.url.absoluteString.condense(matching: query) : (b.url.host() ?? b.url.absoluteString)
            return (path, b.url.absoluteString, false, path.range(of: query, options: .caseInsensitive) != nil, .bookmark)
        case let g as Group:
            let children = g.children(among: entries)
            let gcount = _groups(children).count
            let bookmarks = _bookmarks(children)
            var result = "\(bookmarks.count) bookmarks"
            if gcount > 0 {
                result += " / \(gcount) groups"
            }
            switch hierarchy {
            case .child:
                return (result, nil, false, false, .directory)
            case .descendant:
                return (result, nil, children.count > 0, false, .directory)
            }
        default:
            fatalError("Impossible case")
        }
    }
}

extension WorkbenchViewModel {
    func indentColor(_ index: Int) -> Color {
        if index >= indentColorStorage.count {
            let colors = Array(repeating: Color.random, count: (index + 1) - indentColorStorage.count)
            indentColorStorage.append(contentsOf: colors)
        }
        return indentColorStorage[index]
    }
}

extension WorkbenchViewModel {
    struct Row: LeveledIdentifiable {
        let id: UUID
        let icon: Icon
        let title: String
        let description: String
        let trail: [Group]
        let tags: [String]?
        let expanded: Bool
        let expandable: Bool
        let extra: String?
        let actionable: Bool
        let entryType: EntryType
        
        var level: Int { trail.count }
    }
}

extension WorkbenchViewModel {
    enum Hierarchy {
        case child
        case descendant
    }
}
