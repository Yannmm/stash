//
//  RelicsGuardian.swift
//  Stash
//
//  Created by Rayman on 2025/2/10.
//

import Foundation

class OkamuraCabinet: ObservableObject {
    @Published var entries: [any Entry] = [] {
        didSet {
            print("11111")
        }
    }
    
    static let shared = OkamuraCabinet()
    
    init() {
        Task {
            try await load()
        }
    }
    
    func update(entry: any Entry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
        } else {
            print("you cannot update an entry that is not in entries.")
        }
        save()
    }
    
    func relocate(entry: any Entry, anchorId: UUID?) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries.remove(at: index)
        }
        
        if let aid = anchorId, let index = entries.firstIndex(where: { $0.id == aid }) {
            let anchor = entries[index]
            var copy = entry
            copy.parentId = anchor.location
            entries.insert(copy, at: index)
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
    
    func directoryDefaultName(anchorId: UUID?) -> String {
        var name = "Group"
        var lid: UUID?
        if let aid = anchorId, let anchor = entries.findBy(id: aid), let location = anchor.location {
            lid = location
        }
        
        var existings = [String]()
        
        if let id = lid, let entry = entries.findBy(id: id) {
            existings = entry
                .children(among: entries)
                .map { $0 as? Directory }
                .compactMap { $0 }
                .map { $0.name }
        } else {
            existings = entries.toppings()
                .map { $0 as? Directory }
                .compactMap { $0 }
                .map { $0.name }
        }
        
        let prefix = name
        for i in 0..<Int.max {
            if i == 0 {
            } else {
                name = "\(prefix) \(i)"
            }
            if existings.contains(name) {
                continue
            } else {
                break
            }
        }
        return name
    }
    
    func removeAll() {
        entries = []
        save()
    }
}
