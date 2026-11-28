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
    /// True when every group that has subgroups is expanded.
    @Published private(set) var allExpanded = false
    /// True when at least one group has subgroups, i.e. there is something to expand.
    @Published private(set) var canToggleAll = false
    
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
    
    /// Collapses all groups when all are expanded, otherwise expands every group (including nested ones).
    func toggleAll() {
        if allExpanded {
            expansions = []
        } else {
            expansions = expandableGroupIds(allEntries)
        }
    }
    
    /// Ids of groups that have at least one child group, matching the disclosure rule in `visibleGroups`.
    private func expandableGroupIds(_ entries: [any Entry]) -> Set<UUID> {
        let parentIds = entries.compactMap { ($0 as? Group)?.parentId }
        return Set(parentIds)
    }
    
    func delete(_ id: UUID) {
        guard let entry = entries.findBy(id: id) else { return }
        do {
            try housekeeper.delete(entry: entry)
            wrapper.selection = nil
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
        
        Publishers.CombineLatest(housekeeper.$storedEntries, $expansions)
            .map { [unowned self] entries, expansions in
                let ids = self.expandableGroupIds(entries)
                return (!ids.isEmpty && ids.isSubset(of: expansions), !ids.isEmpty)
            }
            .sink(receiveValue: { [weak self] in
                self?.allExpanded = $0.0
                self?.canToggleAll = $0.1
            })
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
