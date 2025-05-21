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
    
    private let icloudMonitor = IcloudFileMonitor(filename: "default.html")
    
    private let saving = PassthroughSubject<IcloudSignal, Never>()
    
    static let shared = OkamuraCabinet()
    
    private var cancellables = Set<AnyCancellable>()
    
    func icloudComing() {
        saving.send(.increment)
    }
    
    init() {
        asyncLoad()
        bind()
    }
    
    private func asyncLoad() {
        Task {
            try load()
        }
    }
    
    private func bind() {
        icloudMonitor.$update
            .compactMap({ $0 })
            .combineLatest(Just(icloudSync).filter({ $0 }))
            .sink { [weak self] _ in
                self?.saving.send(.increment)
            }
            .store(in: &cancellables)
        
        saving
            .dropFirst()
            .map({ $0.rawValue })
            .scan(0) { accumulated, newValue in
                accumulated + newValue
            }
            .handleEvents(receiveOutput: { value in
                print("doOnData: \(value)")
            })
            .filter({ $0 > 0 })
            .sink { [weak self] value in
                self?.asyncLoad()
                self?.saving.send(.decrement)
            }
            .store(in: &cancellables)

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
        defer { saving.send(.decrement) }
        let data1 = try JSONEncoder().encode(storedEntries.asAnyEntries)
        let url = try whereItIs()
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
        let url = try whereItIs()
        
        let htmlString = try String(contentsOf: url, encoding: .utf8)
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
    
    var icloudSync: Bool { pieceSaver.value(for: .icloudSync) ?? true }
    
    func whereItIs() throws -> URL {
        do {
            if icloudSync {
                return try icloudPath()
            } else {
                return try localPath()
            }
        } catch {
            defer { ErrorTracker.shared.add(error) }
            return try localPath()
        }
    }
    
    private func localPath() throws -> URL {
        let fileManager = FileManager.default
        guard let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { throw SomeError.Save.missingApplicationSupportDirectory}
        let direcotry = support.appendingPathComponent("Stash", isDirectory: true)
        if !fileManager.fileExists(atPath: direcotry.path) {
            try fileManager.createDirectory(at: direcotry, withIntermediateDirectories: true, attributes: nil)
        }
        return direcotry.appendingPathComponent("default.html")
    }
    
    private func icloudPath() throws -> URL {
        let fileManager = FileManager.default
        
        guard let container = fileManager.url(forUbiquityContainerIdentifier: nil) else { throw SomeError.Save.icloudContainerUnavailable  }
        
        let documents = container.appendingPathComponent("Documents")
        
        if !fileManager.fileExists(atPath: documents.path) {
            try fileManager.createDirectory(at: documents, withIntermediateDirectories: true, attributes: nil)
        }
        return documents.appendingPathComponent("default.html")
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
    enum IcloudSignal: Int {
        case increment = 1
        case decrement = -1
    }
}

// TODO
// 1. launch on login
// 2. 没有任何。bookmarks 时，menu太空 // create first bookmark // import from browsers
// 5. 设置窗口有时无法到最前方
// 6. use NSMetadataQuery to monitor file from icloud.
// 3. 排序失去焦点问题
// 4. 一段时间后，好像icloud中的文件被覆盖了

// a. 编辑时不能展开
// b. 链接的反白
// c. 从sub level 到 top level  crash


// 1. add id when saving files.
// 2. animation when expanded
// 3.
