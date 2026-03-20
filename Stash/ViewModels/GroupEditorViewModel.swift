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
    let cabinet: OkamuraCabinet
    
    init(mode: EntryEditor.Mode, cabinet: OkamuraCabinet) {
        self.mode = mode
        self.cabinet = cabinet
        
        switch mode {
        case .create:
            self.savable = false
        case .update(let eid):
            self.savable = false
            let entry = cabinet.storedEntries.filter({ $0.id == eid }).first
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
                if let pid = pid, let index = cabinet.storedEntries.firstIndex(where: { $0.id == pid }) {
                    cabinet.storedEntries.insert(g, at: index + 1)
                } else {
                    cabinet.storedEntries.insert(g, at: 0)
                }
                try cabinet.save()
                
            case .update(let eid):
                guard var old = cabinet.storedEntries.first(where: { $0.id == eid }) as? Group else {
                    throw EntryEditor.CraftError.entryNotFound(eid)
                }
                old.name = t
                old.hashtags = hashtags
                try cabinet.update(entry: old)
            }
        } catch {
            self.error = error
            ErrorTracker.shared.add(error)
        }
    }
}
