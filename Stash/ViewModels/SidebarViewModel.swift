//
//  GroupSectionViewModel.swift
//  Stash
//
//  Created by Rayman on 2026/1/29.
//

import Combine
import Foundation

extension SidebarViewModel {
    func move(_ subjectId: UUID, relativeTo anchorId: UUID, position: DragPosition) {
        guard let subjectIndex = selectionStore.cabinet.storedEntries.firstIndex(where: { $0.id == subjectId }),
              let anchorIndex = selectionStore.cabinet.storedEntries.firstIndex(where: { $0.id == anchorId }),
              subjectIndex != anchorIndex else {
            return
        }
        
        // Get the entry to move
        var subject = selectionStore.cabinet.storedEntries[subjectIndex]
        
        // Create new array with source removed
        var copies = selectionStore.cabinet.storedEntries
        copies.remove(at: subjectIndex)
        
        let anchor = selectionStore.cabinet.storedEntries[anchorIndex]
        subject.parentId = anchor.parentId
        
        // Calculate new target index (adjusted after removal)
        var newIndex = copies.firstIndex(where: { $0.id == anchorId }) ?? 0
        
        // Adjust based on drop position
        switch position {
        case .before:
            newIndex = newIndex - 1
        case .after:
            newIndex = newIndex + 1
        case .in:
            newIndex = newIndex + 1
            subject.parentId = anchorId
        }
        
        // Ensure index is valid
        newIndex = min(max(0, newIndex), copies.count)
        
        // Insert at new position
        copies.insert(subject, at: newIndex)
        
        selectionStore.cabinet.storedEntries = copies
    }
}


class SidebarViewModel: ObservableObject, CascadeJudge {
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
    
    private func visibleGroups(_ entries: [any Entry], _ expansions: Set<UUID>, _ selectionId: UUID?) -> [Row] {
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
