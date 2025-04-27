//
//  RelicsGuardian.swift
//  Stash
//
//  Created by Rayman on 2025/2/10.
//

import Foundation
import AppKit
import UniformTypeIdentifiers
import Combine

class OkamuraCabinet: ObservableObject {
    
    @Published var storedEntries: [any Entry] = []
    
    @Published private(set) var recentEntries: [(Bookmark, String)] = []
    
    static let shared = OkamuraCabinet()
    
    init() {        
        Task {
            try await load()
        }
    }
    
    func update(entry: any Entry) throws {
        if let index = storedEntries.firstIndex(where: { $0.id == entry.id }) {
            storedEntries[index] = entry
            try save()
        }
    }
    
    func relocate(entry: any Entry, anchorId: UUID?) throws {
        if let index = storedEntries.firstIndex(where: { $0.id == entry.id }) {
            storedEntries.remove(at: index)
        }
        
        if let aid = anchorId, let index = storedEntries.firstIndex(where: { $0.id == aid }) {
            let anchor = storedEntries[index]
            var copy = entry
            copy.parentId = anchor.location
            storedEntries.insert(copy, at: index)
        } else {
            storedEntries.append(entry)
        }
        try save()
    }
    
    func save() throws {
        let data = try JSONEncoder().encode(storedEntries.asAnyEntries)
        
        let data1 = try JSONEncoder().encode(recentEntries.map({ $0.0 }).asAnyEntries)
        
        // TODO: save to app documents
        // Save to UserDefaults
        UserDefaults.standard.set(data, forKey: "cabinetEntries1")
        UserDefaults.standard.set(data1, forKey: "recent_entries")
        UserDefaults.standard.set(recentEntries.map({ $0.1 }), forKey: "recent_keys")
    }
    
    func delete(entry: any Entry) throws {
        guard let index = storedEntries.firstIndex(where: { $0.id == entry.id }) else { return }
        storedEntries.remove(at: index)
        try save()
    }
    
    func load() throws {
        guard let data = UserDefaults.standard.data(forKey: "cabinetEntries1") else { return }
        let anyEntries = try JSONDecoder().decode([AnyEntry].self, from: data)
        storedEntries = anyEntries.asEntries
        
        if let data = UserDefaults.standard.data(forKey: "recent_entries"), let keys = UserDefaults.standard.object(forKey: "recent_keys") as? [String] {
            let anyEntries = try JSONDecoder().decode([AnyEntry].self, from: data)
            var aa = [(Bookmark, String)]()
            for (index, entry) in anyEntries.asEntries.enumerated() {
                if let bookmark = entry as? Bookmark, index <= keys.count - 1 {
                    aa.append((bookmark, keys[index]))
                }
            }
            recentEntries = aa
        }
    }
    
    func directoryDefaultName(anchorId: UUID?) -> String {
        var name = "Group"
        var lid: UUID?
        if let aid = anchorId, let anchor = storedEntries.findBy(id: aid), let location = anchor.location {
            lid = location
        }
        
        var existings = [String]()
        
        if let id = lid, let entry = storedEntries.findBy(id: id) {
            existings = entry
                .children(among: storedEntries)
                .map { $0 as? Group }
                .compactMap { $0 }
                .map { $0.name }
        } else {
            existings = storedEntries.toppings()
                .map { $0 as? Group }
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
    
    func removeAll() throws {
        storedEntries = []
        recentEntries = []
        try save()
    }
    
    // TODO: save recentEntries
    func asRecent(_ bookmark: Bookmark) throws {
        var b = bookmark
        b.parentId = nil
        guard recentEntries.firstIndex(where: { $0.0.id == b.id }) == nil else { return }
        var copy = recentEntries
        if (copy.count + 1) > leftyKeystrokes.count {
            copy = Array(copy[0...(leftyKeystrokes.count - 1)])
        }
        
        let kk = Array(copy.map({ $0.1 }))
        
        let kk2 = leftyKeystrokes.filter { !kk.contains($0) }
        
        if kk2.count > 0 {
            copy.insert((b, kk2[0]), at: 0)
        }
        recentEntries = copy
        
        try save()
    }
}

extension OkamuraCabinet {
    func `import`(from filePath: URL) throws {
        let htmlString = try String(contentsOf: filePath, encoding: .utf8)
        let dominator = Dominator()
        let data = try dominator.decompose(htmlString)
        
        let anyEntries = try JSONDecoder().decode([AnyEntry].self, from: data)
        self.storedEntries = anyEntries.asEntries
        try save()
    }
    
    func export(to directoryPath: URL) throws -> URL {
        let data = try JSONEncoder().encode(storedEntries.asAnyEntries)
        let filePath = directoryPath.appendingPathComponent("stash.html")
        try saveToDisk(data: data, filePath: filePath)
        return filePath
    }
}

fileprivate extension OkamuraCabinet {
    func saveToDisk(data: Data, filePath: URL) throws {
        let json = try JSONSerialization.jsonObject(with: data)
        
        let d = Dominator()
        
        let string = try d.compose(json)
        
        try string.write(to: filePath, atomically: true, encoding: .utf8)
    }
}

extension OkamuraCabinet {
    struct SomeError {
        enum Save: Error {
            case missingFilePath
            case invalidJSON
        }
        
        enum Parse: Error, LocalizedError {
            case unsupportedFileType
            
            var errorDescription: String? {
                switch self {
                case .unsupportedFileType:
                    return "Unsupported File Type: Only Netscape Bookmark File format is supported."
                }
            }
        }
    }
    
}
