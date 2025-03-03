//
//  RelicsGuardian.swift
//  Stash
//
//  Created by Rayman on 2025/2/10.
//

import Foundation

class OkamuraCabinet: ObservableObject {
    @Published var entries: [any Entry] = []
    
    static let shared = OkamuraCabinet()
    
    init() {
        Task {
            try await load()
        }
    }
    
    func add(entry: any Entry) {
        entries.append(entry)
        
        save()
    }
    
func save() {
        do {
            // Convert entries to AnyEntry for encoding
            let anyEntries = entries.toAnyEntries()
            let data = try JSONEncoder().encode(anyEntries)
            
            // Save to UserDefaults
            UserDefaults.standard.set(data, forKey: "cabinetEntries")
            print("Saved \(entries.count) entries")
        } catch {
            print("Error saving entries: \(error)")
        }
    }
    
    func load() {
        guard let data = UserDefaults.standard.data(forKey: "cabinetEntries") else {
            print("No saved entries found")
            return
        }
        
        do {
            let anyEntries = try JSONDecoder().decode([AnyEntry].self, from: data)
            entries = [any Entry].fromAnyEntries(anyEntries)
            print("Loaded \(entries.count) entries")
        } catch {
            print("Error loading entries: \(error)")
        }
    }
}
