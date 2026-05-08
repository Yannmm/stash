//
//  RelicsGuardian.swift
//  Stash
//
//  Created by Rayman on 2025/2/10.
//

import Foundation
import UniformTypeIdentifiers
import Combine
import OrderedCollections

class OkamuraCabinet: ObservableObject {
    
    @Published var storedEntries: [any Entry] = []
    
    @Published private(set) var recentEntries: [(Bookmark, String)] = []
    
    private let pieceSaver = PieceSaver()
    private let store = Synchronizer.StashPayloadStore()
    let syncCoordinator: Synchronizer
    
    static let shared = OkamuraCabinet()

    init() {
        let identifier: String? = pieceSaver.value(for: .appIdentifier)
        if identifier == nil {
            pieceSaver.save(for: .appIdentifier, value: UUID().uuidString)
        }
        self.syncCoordinator = Synchronizer(pieceSaver: pieceSaver, store: store)
        self.syncCoordinator.attachRemoteApplyHandler { [weak self] in
            self?.asyncLoad()
        }
        asyncLoad()
        syncCoordinator.requestSync(reason: .startup)
    }
    
    private func asyncLoad() {
        Task {
            do {
                try load()
            } catch {
                ErrorTracker.shared.add(error)
            }
        }
    }
    
    func monitorIcloud() {
        syncCoordinator.requestSync(reason: .providerSwitch)
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
    
    // Does not make any effect for a Bookmark
    func ungroup(entry: any Entry) throws {
        let parentId = entry.parentId
        storedEntries = storedEntries
            .filter({ $0.id != entry.id })
            .map({ e in
                var copy = e
                if copy.parentId == entry.id {
                    copy.parentId = parentId
                }
                return copy
            })
        
        try save()
    }
    
    func save() throws {
        let payload = try store.serialize(entries: storedEntries)
        try store.writePayload(payload, to: try store.localPayloadURL())
        try persistLocalMetadata(for: payload)
        
        // Persist the recent list separately because it contains per-device shortcut state.
        let recents = storedEntries.map({ e in
            if let r = recentEntries.first(where: { $0.0.id == e.id }), let b = e as? Bookmark {
                return (b, r.1)
            } else {
                return Optional<(Bookmark, String)>.none
            }
        }).compactMap({ $0 })
        
        try persistRecents(recents)
        
        DispatchQueue.main.async { [weak self] in
            self?.recentEntries = recents
        }
        syncCoordinator.requestSync(reason: .localChange)
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
        let localURL = try store.localPayloadURL()
        if try store.ensurePayloadExists(at: localURL, entries: storedEntries) {
            self.storedEntries = []
        } else {
            self.storedEntries = try store.readEntries(at: localURL)
        }
        
        self.recentEntries = restoreRecents()
        
        try migrate3_0()
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
        let data = try store.serialize(entries: storedEntries)
        let filePath = directoryPath.appendingPathComponent("nustash\(suffix ?? "").html")
        try store.writePayload(data, to: filePath)
        return filePath
    }
}

fileprivate extension OkamuraCabinet {
    func persistRecents(_ recents: [(Bookmark, String)]) throws {
        let data = try JSONEncoder().encode(recents.map({ $0.0 }).asAnyEntries)
        pieceSaver.save(for: .recentEntries, value: data)
        pieceSaver.save(for: .recentKeys, value: recents.map({ $0.1 }))
    }
    
    func restoreRecents() -> [(Bookmark, String)] {
        guard let data: Data = pieceSaver.value(for: .recentEntries),
              let keys: [String] = pieceSaver.value(for: .recentKeys),
              let anyEntries = try? JSONDecoder().decode([AnyEntry].self, from: data) else {
            return []
        }

        var collector = [(Bookmark, String)]()
        for (index, entry) in anyEntries.asEntries.enumerated() {
            if let bookmark = entry as? Bookmark, index <= keys.count - 1 {
                collector.append((bookmark, keys[index]))
            }
        }
        return collector
    }
    
    func persistLocalMetadata(for payload: Data) throws {
        guard let deviceID: String = pieceSaver.value(for: .appIdentifier) else { return }
        let metadata = Synchronizer.Metadata(
            deviceId: deviceID,
            contentHash: store.contentHash(for: payload),
            revision: UUID().uuidString,
            updatedAt: Date()
        )
        try? store.writeMetadata(metadata, to: store.localMetadataURL())
    }
    
}

extension OkamuraCabinet {
    private func migrate3_0() throws {
        // 1. read from user default to check whether migration has been done
        let flag: Bool = (pieceSaver.value(for: .migration3_0) ?? false)
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
        pieceSaver.save(for: .migration3_0, value: true)
    }
    
    private func parseHashtagsFrom(name text: String, existings: OrderedSet<String>?) -> OrderedSet<String>? {
        let nsrange = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = String.RegexConstant.regex3.matches(in: text, range: nsrange)
        let result = matches.map {
            String(text[Range($0.range, in: text)!])
        }
        
        let whole = (existings ?? []) + result
        
        return whole.count > 0 ? OrderedSet(whole) : nil
    }
}

extension OkamuraCabinet {
    struct SomeError {
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

extension OkamuraCabinet {
    enum Constant {
        static let stashFileName = Synchronizer.StashPayloadStore.Constant.dataFileName
        static let sidecarFileName = Synchronizer.StashPayloadStore.Constant.metadataFileName
    }
}
