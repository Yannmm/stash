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
    @Published var search = ""
    @Published var hierarchy: Hierarchy = .child
    @Published private(set) var rows: [Row] = []
    @Published var hashtagFilter: String?
    var hashtags: [String] {
        let set = Set(dataStore.cabinet.storedEntries
            .map({ $0.hashtags })
            .compactMap({ $0 })
            .flatMap({ $0 }))
        return Array(set)
    }
    
    let dataStore: ManageSelectionStore
    private var _cancellables = Set<AnyCancellable>()
    fileprivate var indentColorStorage = [Color]()
    
    var entries: [any Entry] { dataStore.cabinet.storedEntries }
    
    func updateEntries(_ entries: [any Entry]) {
        dataStore.cabinet.storedEntries = entries
    }
    
    init(selectionStore: ManageSelectionStore) {
        self.dataStore = selectionStore
        
        _bind()
    }
    
    private func _bind() {
        Publishers.CombineLatest4(
            dataStore.$collection,
            dataStore.cabinet.$storedEntries,
            $hierarchy,
            Publishers.CombineLatest($search, $hashtagFilter)
        )
        .map { [unowned self] a, b, c, d in
            let result = self.heirs(b, a, c)
                .map {
                    let tags = $0.hashtags ?? []
                    if let htf = d.1,
                       htf.count > 0,
                       !tags.contains(htf) {
                        return Optional<Row>.none
                    }
                    // TODO: search not implemented
                    let info = _info($0, b, c)
                    return Row(id: $0.id,
                               icon: $0.icon,
                               title: $0.name,
                               description: info.0,
                               trail: trail($0, b, a?.id),
                               tags: Array(tags),
                               expanded: info.1,
                               expandable: $0.container)
                }
                .compactMap({ $0 })
            return result
        }
        .receive(on: DispatchQueue.main)
        .sink(receiveValue: { [weak self] in self?.rows = $0 })
        .store(in: &_cancellables)
        
        $hierarchy
            .map { _ in [] }
            .sink(receiveValue: { [weak self] in self?.indentColorStorage = $0 })
            .store(in: &_cancellables)
    }
    
    var title: String {
        dataStore.collection?.title ?? "All Bookmarks"
    }
    
    var bookmarkCount: Int {
        if let c = dataStore.collection {
            return _bookmarkCount(c.relatedEntries(dataStore.cabinet.storedEntries))
        } else {
            return _bookmarkCount(dataStore.cabinet.storedEntries)
        }
    }
    
    var groupCount: Int {
        if let c = dataStore.collection {
            return _groupCount(c.relatedEntries(dataStore.cabinet.storedEntries))
        } else {
            return _groupCount(dataStore.cabinet.storedEntries)
        }
    }
    
    
    
    private func heirs(_ entries: [any Entry], _ selection: Collectible?, _ hierarchy: Hierarchy) -> [any Entry] {
        switch hierarchy {
        case .child:
            // TODO: selection maybe hashtag as well
            return (selection as? Group).children(among: entries)
        case .descendant:
            // TODO: selection maybe hashtag as well
            return (selection as? Group).descendants(among: entries)
        }
    }
    
    private func _groupCount(_ entries: [any Entry]) -> Int {
        entries.compactMap({ $0 as? Group }).count
    }
    
    private func _bookmarkCount(_ entries: [any Entry]) -> Int {
        entries.compactMap({ $0 as? Bookmark }).count
    }
    
    private func trail(_ target: any Entry, _ entries: [any Entry], _ selectionId: UUID?) -> [Group] {
        var trail = [Group]()
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
    
    private func _info(_ entry: any Entry, _ entries: [any Entry], _ hierarchy: Hierarchy) -> (String, Bool) {
        switch entry {
        case let b as Bookmark:
            return (b.url.host() ?? b.url.absoluteString, false)
        case let g as Group:
            let children = g.children(among: entries)
            let gcount = _groupCount(children)
            let bcount = _bookmarkCount(children)
            var result = "\(bcount) bookmarks"
            if gcount > 0 {
                result += " / \(gcount) groups"
            }
            switch hierarchy {
            case .child:
                return (result, false)
            case .descendant:
                return (result, children.count > 0)
            }
            
        default:
            return ("", false)
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
        
        var level: Int { trail.count }
    }
}

extension WorkbenchViewModel {
    enum Hierarchy {
        case child
        case descendant
    }
}
