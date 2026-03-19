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
        
    }
}
