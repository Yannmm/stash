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
    @Published private var allEntries: [any Entry]
    
    private var _cancellables = Set<AnyCancellable>()
    
    
    init(selection: Collectible?, entries: [any Entry]) {
        self.selection = selection
        self.allEntries = entries
        
//        _bind()
        
        groups = allEntries.groups
    }
}
