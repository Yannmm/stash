//
//  GroupEditorViewModel.swift
//  Stash
//
//  Created by Rayman on 2026/3/19.
//

import AppKit
import Combine
import CombineExt
import OrderedCollections

@MainActor
class GroupEditorViewModel: ObservableObject {
    @Published var savable: Bool
    @Published var hashtags: OrderedSet<String>?
    @Published var title: String?
    @Published var icon: Icon?
    @Published var error: (any Error)?
    
    private var cancellables = Set<AnyCancellable>()
    
    let mode: EntryEditor.Mode
    let housekeeper: Housekeeper
    
    init(mode: EntryEditor.Mode, housekeeper: Housekeeper) {
        self.mode = mode
        self.housekeeper = housekeeper
        
        switch mode {
        case .create:
            self.savable = false
        case .update(let eid):
            self.savable = false
            let entry = housekeeper.storedEntries.filter({ $0.id == eid }).first
            self.title = entry?.name
            self.icon = entry?.icon
            self.hashtags = entry?.hashtags
        }
        
        bind()
    }
    
    private func bind() {
        Publishers.CombineLatest(
            $title
                .removeDuplicates(),
            $hashtags
                .map({ $0 ?? [] })
                .removeDuplicates()
        )
        .dropFirst()
        .filter({ a, b in a != nil })
        .map({ !($0.0!.isEmpty) })
        .receive(on: RunLoop.main)
        .sink { [weak self] p in
            self?.icon = p ? .system("cube.box") : nil
            self?.savable = p
        }
        .store(in: &cancellables)
    }
    
    func save() {
        guard let t = title else { return }
        do {
            switch mode {
            case .create(let pid):
                let g = Group(id: UUID(), name: t, parentId: pid, hashtags: hashtags)
                if let pid = pid, let index = housekeeper.storedEntries.firstIndex(where: { $0.id == pid }) {
                    housekeeper.storedEntries.insert(g, at: index + 1)
                } else {
                    housekeeper.storedEntries.insert(g, at: 0)
                }
                try housekeeper.save()
                
            case .update(let eid):
                guard var old = housekeeper.storedEntries.first(where: { $0.id == eid }) as? Group else {
                    throw EntryEditor.CraftError.entryNotFound(eid)
                }
                old.name = t
                old.hashtags = hashtags
                try housekeeper.update(entry: old)
            }
        } catch {
            self.error = error
            ErrorTracker.shared.add(error)
        }
    }
}
