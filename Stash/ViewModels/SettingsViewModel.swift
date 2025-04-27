//
//  SettingsView.swift
//  Stash
//
//  Created by Yan Meng on 2025/4/27.
//

import Combine
import Foundation

class SettingsViewModel: ObservableObject {
    @Published var collapseHistory: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        collapseHistory = UserDefaults.standard.bool(forKey: "isOnKey")
        
        $collapseHistory
            .sink { UserDefaults.standard.set($0, forKey: "isOnKey") }
            .store(in: &cancellables)
    }
}
