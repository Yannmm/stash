//
//  xxx.swift
//  Stash
//
//  Created by Rayman on 2026/1/12.
//

import Combine
import Foundation
import SwiftUI

class EssentialViewModel: ObservableObject {
    @Published var search = ""
    @Published var hierarchy: Hierarchy = .child
    @Published private(set) var rows: [Row] = []
    
    private let selectionStore: ManageSelectionStore
    private var _cancellables = Set<AnyCancellable>()
    fileprivate var indentColorStorage = [Color]()
    
    init(selectionStore: ManageSelectionStore) {
        self.selectionStore = selectionStore
        
        _bind()
    }
    
    private func _bind() {
        Publishers.CombineLatest4(selectionStore.$collection, selectionStore.cabinet.$storedEntries, $hierarchy, $search)
            .map { [unowned self] a, b, c, d in
                let result = self.heirs(b, a, c).map {
                    Row(id: $0.id,
                        icon: $0.icon,
                        title: $0.name,
                        description: description($0, b),
                        trail: trail($0, b, a?.id) ,
                        tags: $0.name.hashtags)
                }
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
        selectionStore.collection?.title ?? "All Bookmarks"
    }
    
    var bookmarkCount: Int {
        if let c = selectionStore.collection {
            return _bookmarkCount(c.relatedEntries(selectionStore.cabinet.storedEntries))
        } else {
            return _bookmarkCount(selectionStore.cabinet.storedEntries)
        }
    }
    
    var groupCount: Int {
        if let c = selectionStore.collection {
            return _groupCount(c.relatedEntries(selectionStore.cabinet.storedEntries))
        } else {
            return _groupCount(selectionStore.cabinet.storedEntries)
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
    
    private func description(_ entry: any Entry, _ entries: [any Entry]) -> String {
        switch entry {
        case let b as Bookmark:
            return b.url.host() ?? b.url.absoluteString
        case let g as Group:
            let children = g.children(among: entries)
            let gcount = _groupCount(children)
            let bcount = _bookmarkCount(children)
            var result = "\(bcount) bookmarks"
            if gcount > 0 {
                result += " / \(gcount) groups"
            }
            return result
        default:
            return ""
        }
    }
}

extension EssentialViewModel {
    struct Row: Identifiable {
        let id: UUID
        let icon: Icon
        let title: String
        let description: String
        let trail: [Group]
        let tags: [String]
    }
}

extension EssentialViewModel {
    enum Hierarchy {
        case child
        case descendant
    }
}

extension EssentialViewModel {
    /// Move an entry from source position to before/after target position
    func moveRow(_ subjectId: UUID, to destinationId: UUID, insertAfter: Bool) {
        // Find indices in allEntries
        guard let subjectIndex = selectionStore.cabinet.storedEntries.firstIndex(where: { $0.id == subjectId }),
              let destinationIndex = selectionStore.cabinet.storedEntries.firstIndex(where: { $0.id == destinationId }),
              subjectIndex != destinationIndex else {
            return
        }
        
        // Get the entry to move
        var subject = selectionStore.cabinet.storedEntries[subjectIndex]
        
        // Create new array with source removed
        var copies = selectionStore.cabinet.storedEntries
        copies.remove(at: subjectIndex)
        
        let destination = selectionStore.cabinet.storedEntries[destinationIndex]
        subject.parentId = destination.parentId
        
        // Calculate new target index (adjusted after removal)
        var newIndex = copies.firstIndex(where: { $0.id == destinationId }) ?? 0
        
        // Adjust based on drop position
        if insertAfter {
            newIndex += 1
        }
        
        // Ensure index is valid
        newIndex = min(max(0, newIndex), copies.count)
        
        // Insert at new position
        copies.insert(subject, at: newIndex)
        
        selectionStore.cabinet.storedEntries = copies
    }
}

extension EssentialViewModel {
    func indentColor(_ index: Int) -> Color {
        if index >= indentColorStorage.count {
            let colors = Array(repeating: Color.random, count: (index + 1) - indentColorStorage.count)
            indentColorStorage.append(contentsOf: colors)
        }
        return indentColorStorage[index]
    }
}
