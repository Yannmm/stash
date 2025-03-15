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
    
    func upsert(entry: any Entry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
        } else {
            entries.append(entry)
        }
        save()
    }
    
    func save() {
        do {
            let data = try JSONEncoder().encode(entries.asAnyEntries)
            
            // Save to UserDefaults
            UserDefaults.standard.set(data, forKey: "cabinetEntries1")
            print("Saved \(entries.count) entries")
        } catch {
            print("Error saving entries: \(error)")
        }
    }
    
    func load() {
        guard let data = UserDefaults.standard.data(forKey: "cabinetEntries1") else {
            print("No saved entries found")
            return
        }
        
        do {
            let anyEntries = try JSONDecoder().decode([AnyEntry].self, from: data)
            entries = anyEntries.asEntries
            print("Loaded \(entries.count) entries")
        } catch {
            print("Error loading entries: \(error)")
        }
    }
}
