//
//  GroupSectionViewModel.swift
//  Stash
//
//  Created by Rayman on 2026/1/29.
//

import Combine
import Foundation

class SidebarViewModel: ObservableObject {
    @Published private var expansions: Set<UUID> = []
    @Published var hashtags: [Hashtag] = []
    @Published private(set) var rows: [Row] = []
    
    private var allEntries: [any Entry] {
        selectionStore.cabinet.storedEntries
    }
    
    func toggleExpansion(_ id: UUID) {
        if expansions.contains(id) {
            expansions.remove(id)
        } else {
            expansions.insert(id)
        }
    }
    
    func setSelection(_ id: UUID) {
        selectionStore.collection = allEntries.filter { $0.id == id }.first as? Group
    }
    
    let selectionStore: ManageSelectionStore
    private var _cancellables = Set<AnyCancellable>()
    
    
    init(selectionStore: ManageSelectionStore) {
        self.selectionStore = selectionStore
        
        _bind()
    }
    
    private func _bind() {
        Publishers.CombineLatest3(selectionStore.cabinet.$storedEntries, $expansions, selectionStore.$collection)
            .map { [unowned self] a, b, c in
                self.visibleGroups(a, b, c?.id)
            }
            .sink(receiveValue: { [weak self] in self?.rows = $0 })
            .store(in: &_cancellables)
    }
    
    private func visibleGroups(_ entries: [any Entry], _ expansions: Set<UUID>, _ selection: UUID?) -> [Row] {
        let allGroups = entries.compactMap { $0 as? Group }
        var result = [Row]()
        func flatten(_ group: Group, level: Int) {
            let expanded = expansions.contains(group.id)
            let children = group.children(among: entries)
            let gcount = children.compactMap { $0 as? Group }.count
            let bcount = children.compactMap { $0 as? Bookmark }.count
            result.append(
                Row(id: group.id,
                    name: group.name,
                    level: level,
                    expanded: expanded,
                    groupCount: gcount,
                    bookmarkCount: bcount,
                    selected: group.id == selection)
            )
            if expanded {
                let children = allGroups.filter { $0.parentId == group.id }
                for child in children {
                    flatten(child, level: level + 1)
                }
            }
        }
        for root in allGroups.filter({ $0.parentId == nil }) {
            flatten(root, level: 0)
        }
        return result
    }
}

extension SidebarViewModel {
    struct Row {
        let id: UUID
        let name: String
        let level: Int
        let expanded: Bool
        let groupCount: Int
        let bookmarkCount: Int
        let selected: Bool
    }
}
