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
import OrderedCollections

class Housekeeper: ObservableObject {
    
    @Published var storedEntries: [any Entry] = []
    
    @Published private(set) var recentEntries: [(Bookmark, String)] = []
    
    let synchronizer: Synchronizer
    
    private var cancellables = Set<AnyCancellable>()
    
    init(synchronizer: Synchronizer) {
        self.synchronizer = synchronizer
    }
    
    func update(entry: any Entry) throws {
        if let index = storedEntries.firstIndex(where: { $0.id == entry.id }) {
            storedEntries[index] = entry
            try save()
        }
    }
    
    func relocate(entry: any Entry, anchorId: UUID?) throws {
        if let index = storedEntries.firstIndex(where: { $0.id == entry.id }) {
            // Seems this never happens
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
    
    func delete(entry: any Entry) throws {
        if let index = recentEntries.firstIndex(where: { $0.0.id == entry.id }) {
            recentEntries.remove(at: index)
        }
        if let index = storedEntries.firstIndex(where: { $0.id == entry.id }) {
            storedEntries.remove(at: index)
            try save()
        }
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

extension Housekeeper {
    func save() throws {
        let html = try toNetscapeBookmarkFile()
        Task.detached {
            try await self.synchronizer.save(document: html)
        }
        
        // In case for import
        let recents = storedEntries.map({ e in
            if let r = recentEntries.first(where: { $0.0.id == e.id }), let b = e as? Bookmark {
                return (b, r.1)
            } else {
                return Optional<(Bookmark, String)>.none
            }
        }).compactMap({ $0 })
        
        let data2 = try JSONEncoder().encode(recents.map({ $0.0 }).asAnyEntries)
        Pref.save(for: Pref.Key.recentEntries, value: data2)
        Pref.save(for: Pref.Key.recentKeys, value: recents.map({ $0.1 }))
        
        DispatchQueue.main.async { [weak self] in
            self?.recentEntries = recents
        }
    }
    
    private func load() {
        // Task {} will inherit MainActor but Task.detached does not.
        Task.detached(priority: .utility) { [weak self] in
            do {
                try self?._load()
            } catch {
                ErrorTracker.shared.add(error)
            }
        }
    }
    
    private func _load() throws {
        let htmlString = try synchronizer.load()
        let dominator = Dominator()
        let data = try dominator.decompose(htmlString)
        
        let anyEntries = try JSONDecoder().decode([AnyEntry].self, from: data)
        
        self.storedEntries = anyEntries.asEntries
        
        if let data = Pref.value(for: Pref.Key.recentEntries),
           let keys = Pref.value(for: Pref.Key.recentKeys) {
            let anyEntries = try JSONDecoder().decode([AnyEntry].self, from: data)
            var collector = [(Bookmark, String)]()
            for (index, entry) in anyEntries.asEntries.enumerated() {
                if let bookmark = entry as? Bookmark, index <= keys.count - 1 {
                    collector.append((bookmark, keys[index]))
                }
            }
            self.recentEntries = collector
        }
        
        try migrate3_0()
    }
}

extension Housekeeper {
    func `import`(from filePath: URL, fileType: String.FileType, replace: Bool) throws {
        let content = try String(contentsOf: filePath, encoding: .utf8)
        var entries = [any Entry]()
        switch fileType {
        case .netscape:
            let dominator = Dominator()
            let data = try dominator.decompose(content)
            let anyEntries = try JSONDecoder().decode([AnyEntry].self, from: data)
            entries = anyEntries.asEntries
        case .hungrymarks:
            let parser = HungrymarkParser()
            entries = parser.parse(text: content)
        case .pocket:
            let parser = CsvParser()
            let anyEntries = try parser.parse(from: content)
            entries = anyEntries.asEntries
        }
        
        if !replace {
            var conflictIds = [(UUID, UUID)]()
            let ids = Set(storedEntries.map({ $0.id }))
            
            let name = String(filePath.lastPathComponent.split(separator: ".")[0])
            let group = Group(id: UUID(), name: name, hashtags: [])
            var entries = entries.map({ e in
                var copy = e
                if copy.parentId == nil {
                    copy.parentId = group.id
                }
                
                if ids.contains(copy.id) {
                    let newId = UUID()
                    conflictIds.append((copy.id, newId))
                    copy.id = newId
                }
                
                return copy
            })
            
            for t2 in conflictIds {
                entries = entries.map({ e in
                    var copy = e
                    if copy.parentId == t2.0 {
                        copy.parentId = t2.1
                    }
                    return copy
                })
            }
            
            entries.insert(group, at: 0)
            storedEntries.append(contentsOf: entries)
        } else {
            self.storedEntries = entries
        }
        
        try save()
    }
    
    @discardableResult
    func export(to directoryPath: URL, suffix: String? = nil) throws -> URL {
        let html = try toNetscapeBookmarkFile()
        let filePath = directoryPath.appendingPathComponent("nustash\(suffix ?? "").html")
        try html.write(to: filePath, atomically: true, encoding: .utf8)
        return filePath
    }
}

fileprivate extension Housekeeper {
    func toNetscapeBookmarkFile() throws -> String {
        let data = try JSONEncoder().encode(storedEntries.asAnyEntries)
        let json = try JSONSerialization.jsonObject(with: data)
        let d = Dominator()
        let string = try d.compose(json)
        return string
    }
}

private extension Housekeeper {
    func migrate3_0() throws {
        // 1. read from user default to check whether migration has been done
        let flag = Pref.value(for: Pref.Key.migration3_0) ?? false
        guard !flag else { return }
        // 2. if not, update storedEntries .hashtags accordign to title
        let result = self.storedEntries.map({ e in
            var copy = e
            copy.hashtags = parseHashtagsFrom(name: copy.name, existings: copy.hashtags)
            return copy
        })
        // 3. save
        self.storedEntries = result
        try save()
        // 4. update flag from user defaults
        Pref.save(for: Pref.Key.migration3_0, value: true)
    }
    
    func parseHashtagsFrom(name text: String, existings: OrderedSet<String>?) -> OrderedSet<String>? {
        let nsrange = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = String.RegexConstant.regex3.matches(in: text, range: nsrange)
        let result = matches.map {
            String(text[Range($0.range, in: text)!])
        }
        
        let whole = (existings ?? []) + result
        
        return whole.count > 0 ? OrderedSet(whole) : nil
    }
}

extension Housekeeper {
    struct SomeError {
        enum Save: Error {
            case missingFilePath
            case invalidJSON
            case missingApplicationSupportDirectory
            case icloudContainerUnavailable
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

// 1. 启动时存入一个uuid
// 2. 每当 save 时，创建一个文件，并写入上面的 uuid （如果 enable icloud sync）
// 3. 开启 icloud sync 时，执行一遍 2
// 3. 启动时，开始监听上述文件，（如果 enable icloud sync）
// 4. 如果上述文件有变化，则读取内容，比较uuid
// 5. 一致，忽略，不一致，reload stash.html
