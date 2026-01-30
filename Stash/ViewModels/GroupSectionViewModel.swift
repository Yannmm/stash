//
//  GroupSectionViewModel.swift
//  Stash
//
//  Created by Rayman on 2026/1/29.
//

import Combine
import Foundation

class GroupSectionViewModel: ObservableObject {
    @Published var expansions: Set<UUID> = []
    @Published var hashtags: [Hashtag] = []
    @Published private(set) var rows: [Row] = []
    
    private var allEntries: [any Entry] {
        _selectionStore.cabinet.storedEntries
    }
    
    
    private let _selectionStore: ManageSelectionStore
    private var _cancellables = Set<AnyCancellable>()
    
    
    init(selectionStore: ManageSelectionStore) {
        self._selectionStore = selectionStore
        rows = visibleGroups(_selectionStore.cabinet.storedEntries, expansions)
    }
    
    private func visibleGroups(_ entries: [any Entry], _ expansions: Set<UUID>) -> [Row] {
        let allGroups = entries.compactMap { $0 as? Group }
        var result = [Row]()
        func flatten(_ group: Group, level: Int) {
            let expanded = expansions.contains(group.id)
            result.append(Row(id: group.id, name: group.name, level: level, expanded: expanded))
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

extension GroupSectionViewModel {
    struct Row {
        let id: UUID
        let name: String
        let level: Int
        let expanded: Bool
    }
}
