//
//  GroupSectionViewModel.swift
//  Stash
//
//  Created by Rayman on 2026/1/29.
//

import Combine
import Foundation

class SidebarViewModel: ObservableObject, CascadeJudge {
    @Published private var expansions: Set<UUID> = []
    @Published var hashtags: [Hashtag] = []
    @Published private(set) var rows: [Row] = []
    @Published private(set) var rootRow: Row!
    @Published var error: Error?
    
    var entries: [any Entry] { housekeeper.storedEntries }
    
    func update(_ entries: [any Entry]) {
        housekeeper.storedEntries = entries
        do {
            try housekeeper.save()
        } catch {
            self.error = error
        }
    }
    
    private var allEntries: [any Entry] {
        housekeeper.storedEntries
    }
    
    func toggleExpansion(_ id: UUID) {
        if expansions.contains(id) {
            expansions.remove(id)
        } else {
            expansions.insert(id)
        }
    }
    
    private var _cancellables = Set<AnyCancellable>()
    let housekeeper: Housekeeper
    let wrapper: GroupSelectionWrapper
    
    init(housekeeper: Housekeeper, wrapper: GroupSelectionWrapper) {
        self.wrapper = wrapper
        self.housekeeper = housekeeper
        _bind()
    }
    
    private func _bind() {
        Publishers.CombineLatest3(housekeeper.$storedEntries, $expansions, wrapper.$selection)
            .map { [unowned self] a, b, c in
                self.visibleGroups(a, b, c)
            }
            .sink(receiveValue: { [weak self] in self?.rows = $0 })
            .store(in: &_cancellables)
        
        Publishers.CombineLatest(housekeeper.$storedEntries, wrapper.$selection)
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
    
    private func visibleGroups(_ entries: [any Entry], _ expansions: Set<UUID>, _ selectionId: UUID?) -> [Row] {
        let allGroups = entries.compactMap { $0 as? Group }
        var result = [Row]()
        func flatten(_ group: Group, level: Int) {
            let children = group.children(among: entries)
            let gcount = children.compactMap { $0 as? Group }.count
            let bcount = children.compactMap { $0 as? Bookmark }.count
            let expanded = expansions.contains(group.id) && gcount > 0
            result.append(
                Row(id: group.id,
                    name: group.name,
                    level: level,
                    expanded: expanded,
                    groupCount: gcount,
                    bookmarkCount: bcount,
                    selected: group.id == selectionId)
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
    struct Row: LeveledIdentifiable {
        let id: UUID
        let name: String
        let level: Int
        let expanded: Bool
        let groupCount: Int
        let bookmarkCount: Int
        let selected: Bool
    }
}
