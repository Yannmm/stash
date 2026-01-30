//
//  GroupSectionViewModel.swift
//  Stash
//
//  Created by Rayman on 2026/1/29.
//

import Combine
import Foundation

class GroupSectionViewModel: ObservableObject {
    @Published var selection: Collectible?
    @Published var expansions: Set<UUID> = []
    @Published var hashtags: [Hashtag] = []
    @Published private(set) var groups: [Group] = []
    
    private var allEntries: [any Entry] {
        _selectionStore.cabinet.storedEntries
    }
    
    
    private let _selectionStore: ManageSelectionStore
    private var _cancellables = Set<AnyCancellable>()
    
    
    init(selectionStore: ManageSelectionStore) {
        self._selectionStore = selectionStore
        
        
//        _bind()
        
        groups = allEntries.groups
    }
}
