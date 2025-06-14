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
    
    private var icloudMonitor: IcloudFileMonitor?
    
    private var icloudMonitorSubscription: AnyCancellable?
    
    static let shared = OkamuraCabinet()
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        asyncLoad()
        monitorIcloud()
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
        icloudMonitorSubscription?.cancel()
        icloudMonitor = nil
        if icloudSync {
            icloudMonitor = IcloudFileMonitor(filename: Constant.sidecarFileName)
            icloudMonitorSubscription = icloudMonitor?.$onChange
                .compactMap({ $0 })
                .combineLatest(Just(icloudSync).filter({ $0 }))
                .tryMap({ try String(contentsOf: $0.0, encoding: .utf8) })
                .catch { error -> AnyPublisher<String, Never> in
                    ErrorTracker.shared.add(error)
                    return Empty().eraseToAnyPublisher()
                }
                .map({ UUID(uuidString: $0) })
                .combineLatest(Just<String?>(pieceSaver.value(for: .appIdentifier))
                    .compactMap({ $0 })
                    .map({ UUID(uuidString: $0) }))
                .handleEvents(receiveOutput: { value in
                    print("doOnData: \(value)")
                })
                .filter({ $0.0 != $0.1 })
                .delay(for: .seconds(2), scheduler: RunLoop.main)
                .sink(receiveValue: { [weak self] _ in
                    self?.asyncLoad()
                })
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
    
    func save() throws {
        let data1 = try JSONEncoder().encode(storedEntries.asAnyEntries)
        let urls = try whereItIs()
        try saveToDisk(data: data1, filePath: urls.0, sidecarPath: urls.1)
        
        // In case for import
        let copy = recentEntries
        let ids = storedEntries.map({ $0.id })
        let recents = copy.filter({ ids.contains($0.0.id) })
        
        let data2 = try JSONEncoder().encode(recents.map({ $0.0 }).asAnyEntries)
        pieceSaver.save(for: .recentEntries, value: data2)
        pieceSaver.save(for: .recentKeys, value: recents.map({ $0.1 }))
        
        DispatchQueue.main.async { [weak self] in
            self?.recentEntries = recents
        }
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
        let urls = try whereItIs()
        
        let htmlString = try String(contentsOf: urls.0, encoding: .utf8)
        let dominator = Dominator()
        let data = try dominator.decompose(htmlString)
        
        let anyEntries = try JSONDecoder().decode([AnyEntry].self, from: data)
        
        // Move UI updates to main thread
        DispatchQueue.main.async { [weak self] in
            self?.storedEntries = anyEntries.asEntries
        }
        
        if let data: Data = pieceSaver.value(for: .recentEntries),
           let keys: [String] = pieceSaver.value(for: .recentKeys) {
            let anyEntries = try JSONDecoder().decode([AnyEntry].self, from: data)
            var collector = [(Bookmark, String)]()
            for (index, entry) in anyEntries.asEntries.enumerated() {
                if let bookmark = entry as? Bookmark, index <= keys.count - 1 {
                    collector.append((bookmark, keys[index]))
                }
            }
            // Move UI updates to main thread
            DispatchQueue.main.async { [weak self] in
                self?.recentEntries = collector
            }
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
    func `import`(from filePath: URL, replace: Bool) throws {
        let content = try String(contentsOf: filePath, encoding: .utf8)
        var entries = [any Entry]()
        switch content.checkFileType() {
        case .netscape:
            let dominator = Dominator()
            let data = try dominator.decompose(content)
            let anyEntries = try JSONDecoder().decode([AnyEntry].self, from: data)
            entries = anyEntries.asEntries
        case .hungrymarks:
            let parser = HungrymarkParser()
            entries = parser.parse(text: content)
        }
        
        if !replace {
            let name = String(filePath.lastPathComponent.split(separator: ".")[0])
            let group = Group(id: UUID(), name: name)
            var entries = entries.map({ e in
                var copy = e
                if copy.parentId == nil {
                    copy.parentId = group.id
                }
                return copy
            })
            entries.insert(group, at: 0)
            storedEntries.append(contentsOf: entries)
        } else {
            self.storedEntries = entries
        }
        
        try save()
    }
    
    @discardableResult
    func export(to directoryPath: URL, suffix: String? = nil) throws -> URL {
        let data = try JSONEncoder().encode(storedEntries.asAnyEntries)
        let filePath = directoryPath.appendingPathComponent("stash\(suffix ?? "").html")
        try saveToDisk(data: data, filePath: filePath)
        return filePath
    }
}

fileprivate extension OkamuraCabinet {
    func saveToDisk(data: Data, filePath: URL, sidecarPath: URL? = nil) throws {
        let json = try JSONSerialization.jsonObject(with: data)
        let d = Dominator()
        let string = try d.compose(json)
        try string.write(to: filePath, atomically: true, encoding: .utf8)
        if let path = sidecarPath, let appId: String = pieceSaver.value(for: .appIdentifier) {
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 2) {
                do {
                    try appId.write(to: path, atomically: true, encoding: .utf8)
                } catch {
                    ErrorTracker.shared.add(error)
                }
            }
        }
    }
    
    var icloudSync: Bool { pieceSaver.value(for: .icloudSync) ?? true }
    
    // (stash.html path, icloud sidecar path?)
    func whereItIs() throws -> (URL, URL?) {
        do {
            if icloudSync {
                return try icloudPath()
            } else {
                return (try localPath(), nil)
            }
        } catch {
            defer { ErrorTracker.shared.add(error) }
            return (try localPath(), nil)
        }
    }
    
    private func localPath() throws -> URL {
        let fileManager = FileManager.default
        guard let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { throw SomeError.Save.missingApplicationSupportDirectory}
        let direcotry = support.appendingPathComponent("Stash", isDirectory: true)
        if !fileManager.fileExists(atPath: direcotry.path) {
            try fileManager.createDirectory(at: direcotry, withIntermediateDirectories: true, attributes: nil)
        }
        return direcotry.appendingPathComponent(Constant.stashFileName)
    }
    
    private func icloudPath() throws -> (URL, URL) {
        let fileManager = FileManager.default
        
        guard let container = fileManager.url(forUbiquityContainerIdentifier: nil) else { throw SomeError.Save.icloudContainerUnavailable  }
        
        let documents = container.appendingPathComponent("Documents")
        
        if !fileManager.fileExists(atPath: documents.path) {
            try fileManager.createDirectory(at: documents, withIntermediateDirectories: true, attributes: nil)
        }
        return (documents.appendingPathComponent(Constant.stashFileName), documents.appendingPathComponent(Constant.sidecarFileName))
    }
    
}

extension OkamuraCabinet {
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

extension OkamuraCabinet {
    enum Constant {
        static let stashFileName = "default.html"
        static let sidecarFileName = "default.html.sidecar"
    }
}

// 1. 启动时存入一个uuid
// 2. 每当 save 时，创建一个文件，并写入上面的 uuid （如果 enable icloud sync）
// 3. 开启 icloud sync 时，执行一遍 2
// 3. 启动时，开始监听上述文件，（如果 enable icloud sync）
// 4. 如果上述文件有变化，则读取内容，比较uuid
// 5. 一致，忽略，不一致，reload stash.html
