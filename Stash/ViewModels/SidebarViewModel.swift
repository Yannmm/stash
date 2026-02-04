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
    @Published private(set) var rootRow: Row!
    
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
    
    func setSelection(_ id: UUID?) {
        selectionStore.collection = id == nil ? nil : (allEntries.filter { $0.id == id }.first as? Group)
    }
    
    func effectiveChildrenCount(_ id: UUID) -> Int {
        guard let index = rows.firstIndex(where: { $0.id == id }), rows[index].expanded else { return 0 }
        let level = rows[index].level
        var count = 0
        for row in rows[(index + 1)...] {
            guard level < row.level else { break }
            count += 1
        }
        
        return count
    }
    
    // TODO: expand will hinder adjacent
    func adjacent(_ hostId: UUID, guestId: UUID) -> Bool {
        guard let hostIndex = rows.firstIndex(where: { $0.id == hostId }),
              let guestIndex = rows.firstIndex(where: { $0.id == guestId }),
              hostIndex != guestIndex,
              rows[hostIndex].level != rows[guestIndex].level else {
            return false
        }
        
        if hostIndex < guestIndex {
            for row in rows[(hostIndex + 1)...guestIndex].reversed() {
                if row.level <= rows[hostIndex].level {
                    return false
                }
            }
        } else {
            for row in rows[(guestIndex + 1)...hostIndex].reversed() {
                if row.level <= rows[guestIndex].level {
                    return false
                }
            }
        }
        return true
    }
    
    func handleDrop(_ guestId: UUID, to hostId: UUID) {
        
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
        
        Publishers.CombineLatest(selectionStore.cabinet.$storedEntries, selectionStore.$collection.map { $0?.id })
            .map { a, b in
                Row(
                    id: UUID(),
                    name: "All Bookmarks",
                    level: 0,
                    expanded: false,
                    groupCount: a.compactMap { $0 as? Group }.count,
                    bookmarkCount: a.compactMap { $0 as? Bookmark }.count,
                    selected: b == nil)
                
            }
            .sink(receiveValue: { [weak self] in self?.rootRow = $0 })
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
