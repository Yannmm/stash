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
    
    private let pieceSaver = PieceSaver()
    
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
        let data1 = try JSONEncoder().encode(storedEntries.asAnyEntries)
        let url = try getAppSupportDirectory(appName: "Stash")
        try saveToDisk(data: data1, filePath: url)
        
        // In case for import
        let copy = recentEntries
        let ids = storedEntries.map({ $0.id })
        DispatchQueue.main.async { [weak self] in
            self?.recentEntries = copy.filter({ ids.contains($0.0.id) })
        }

        let data2 = try JSONEncoder().encode(recentEntries.map({ $0.0 }).asAnyEntries)
        pieceSaver.save(for: .recentEntries, value: data2)
        pieceSaver.save(for: .recentKeys, value: recentEntries.map({ $0.1 }))
    }
    
    func delete(entry: any Entry) throws {
        if let index = recentEntries.firstIndex(where: { $0.0.id == entry.id }) {
            recentEntries.remove(at: index)
        }
        if let index = storedEntries.firstIndex(where: { $0.id == entry.id }) {
            storedEntries.remove(at: index)
            try save()
        }
    }
    
    func load() throws {
        let filePath = try getAppSupportDirectory(appName: "Stash")
        
        let htmlString = try String(contentsOf: filePath, encoding: .utf8)
        let dominator = Dominator()
        let data = try dominator.decompose(htmlString)
        
        let anyEntries = try JSONDecoder().decode([AnyEntry].self, from: data)
        storedEntries = anyEntries.asEntries
        
        
        if let data: Data = pieceSaver.value(for: .recentEntries),
           let keys: [String] = pieceSaver.value(for: .recentKeys) {
            let anyEntries = try JSONDecoder().decode([AnyEntry].self, from: data)
            var collector = [(Bookmark, String)]()
            for (index, entry) in anyEntries.asEntries.enumerated() {
                if let bookmark = entry as? Bookmark, index <= keys.count - 1 {
                    collector.append((bookmark, keys[index]))
                }
            }
            recentEntries = collector
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
    
    func asRecent(_ bookmark: Bookmark) throws {
        var b = bookmark
        b.parentId = nil
        guard recentEntries.firstIndex(where: { $0.0.id == b.id }) == nil else { return }
        var copy = recentEntries
        if (copy.count + 1) > leftyKeystrokes.count {
            copy = Array(copy[0...(leftyKeystrokes.count - 1)])
        }
        let existings = Array(copy.map({ $0.1 }))
        let rest = leftyKeystrokes.filter { !existings.contains($0) }
        if rest.count > 0 {
            copy.insert((b, rest[0]), at: 0)
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
    
    func export(to directoryPath: URL) throws {
        let data = try JSONEncoder().encode(storedEntries.asAnyEntries)
        let filePath = directoryPath.appendingPathComponent("stash.html")
        try saveToDisk(data: data, filePath: filePath)
    }
}

fileprivate extension OkamuraCabinet {
    func saveToDisk(data: Data, filePath: URL) throws {
        let json = try JSONSerialization.jsonObject(with: data)
        let d = Dominator()
        let string = try d.compose(json)
        try string.write(to: filePath, atomically: true, encoding: .utf8)
    }
    
    func getAppSupportDirectory(appName: String) throws -> URL {
        let fileManager = FileManager.default
        
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw SomeError.Save.missingApplicationSupportDirectory
        }
        
        let appDirectory = appSupportURL.appendingPathComponent(appName, isDirectory: true)
        
        if !fileManager.fileExists(atPath: appDirectory.path) {
            try fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        
        return appDirectory.appendingPathComponent("default.html")
    }

}

extension OkamuraCabinet {
    struct SomeError {
        enum Save: Error {
            case missingFilePath
            case invalidJSON
            case missingApplicationSupportDirectory
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
