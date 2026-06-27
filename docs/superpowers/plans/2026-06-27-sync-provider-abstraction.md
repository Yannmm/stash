# Sync Provider Abstraction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the monolithic synchronization system with a provider-based abstraction where Local and iCloud are interchangeable sync backends.

**Architecture:** Local-as-hub — all edits write locally first, then push to the selected remote provider. Each provider conforms to a `Provider` protocol exposing `incoming` (publisher), `readSidecar()`, `readDocument()`, `send()`, and `checkAvailability()`. Conflict resolution is "latest timestamp wins" via a JSON sidecar file.

**Tech Stack:** Swift, Combine, Foundation (NSMetadataQuery for iCloud monitoring, JSONEncoder/Decoder for sidecar)

## Global Constraints

- macOS only (AppKit, no UIKit)
- Combine for reactive streams (no async sequences)
- Device name via `Host.current().localizedName!`
- Sidecar format: JSON with keys `uid`, `timestamp`, `device`
- File names: `nustash_index.html` (document), `nustash_index.html.sidecar` (sidecar)
- Only Local + iCloud providers in scope; Dropbox stubbed to compile

---

## File Structure

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `Stash/Synchronization/SidecarData.swift` | Codable struct for sidecar JSON |
| Create | `Stash/Synchronization/SyncHistory.swift` | `Synchronizer.History` — audit log |
| Rewrite | `Stash/Synchronization/Synchronizer.swift` | Orchestrator with new protocol + flows |
| Rewrite | `Stash/Synchronization/LocalStorageProvider.swift` | Hub provider with `write(html:)` |
| Rewrite | `Stash/Synchronization/AiCloudProvider.swift` | iCloud provider with monitor |
| Modify | `Stash/Synchronization/DropboxProvider.swift` | Stub to compile against new protocol |
| Modify | `Stash/ViewModels/HouseKeeper.swift` | Subscribe to `onRemoteDataApplied` |
| Modify | `Stash/ViewModels/SettingsViewModel.swift` | Add `refreshAvailability()` |
| Modify | `Stash/AppDelegate.swift` | Wire new init + `applicationDidBecomeActive` |
| Remove key | `Stash/Helpers/Pref.swift` | Remove `appIdentifier` key (replaced by sidecar UID) |

---

### Task 1: SidecarData

**Files:**
- Create: `Stash/Synchronization/SidecarData.swift`

**Interfaces:**
- Consumes: nothing
- Produces: `struct SidecarData: Codable, Equatable` with properties `uid: String`, `timestamp: Date`, `device: String`; static factory `SidecarData.stamp()` that generates a fresh instance

- [ ] **Step 1: Create SidecarData.swift**

```swift
import Foundation

struct SidecarData: Codable, Equatable {
    let uid: String
    let timestamp: Date
    let device: String

    static func stamp() -> SidecarData {
        SidecarData(
            uid: UUID().uuidString,
            timestamp: Date(),
            device: Host.current().localizedName ?? "Unknown"
        )
    }
}
```

- [ ] **Step 2: Verify it compiles**

Run: Cmd+B in Xcode (or `xcodebuild -scheme Stash build`)
Expected: clean build, no errors

- [ ] **Step 3: Commit**

```bash
git add Stash/Synchronization/SidecarData.swift
git commit -m "feat: add SidecarData model for sync sidecar file"
```

---

### Task 2: Synchronizer.History

**Files:**
- Create: `Stash/Synchronization/SyncHistory.swift`

**Interfaces:**
- Consumes: `SidecarData`
- Produces: `Synchronizer.History` with `func log(action:sidecar:)`, `var entries: [Entry]`

- [ ] **Step 1: Create SyncHistory.swift**

```swift
import Foundation

extension Synchronizer {
    final class History {
        struct Entry: Codable {
            let timestamp: Date
            let device: String
            let action: String
        }

        private let fileURL: URL
        private let cap = 100
        private(set) var entries: [Entry] = []

        init() {
            let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let dir = support.appendingPathComponent("Stash", isDirectory: true)
            if !FileManager.default.fileExists(atPath: dir.path) {
                try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            }
            fileURL = dir.appendingPathComponent("sync_history.json")
            load()
        }

        func log(action: String, sidecar: SidecarData) {
            let entry = Entry(timestamp: sidecar.timestamp, device: sidecar.device, action: action)
            entries.append(entry)
            if entries.count > cap {
                entries = Array(entries.suffix(cap))
            }
            save()
        }

        private func load() {
            guard let data = try? Data(contentsOf: fileURL) else { return }
            entries = (try? JSONDecoder().decode([Entry].self, from: data)) ?? []
        }

        private func save() {
            guard let data = try? JSONEncoder().encode(entries) else { return }
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}
```

- [ ] **Step 2: Verify it compiles**

Run: Cmd+B
Expected: clean build

- [ ] **Step 3: Commit**

```bash
git add Stash/Synchronization/SyncHistory.swift
git commit -m "feat: add Synchronizer.History audit log"
```

---

### Task 3: Provider Protocol & Synchronizer Shell

**Files:**
- Rewrite: `Stash/Synchronization/Synchronizer.swift`

**Interfaces:**
- Consumes: `SidecarData`, `Synchronizer.History`
- Produces: `Synchronizer.Provider` protocol, `Synchronizer` orchestrator class with `save(document:)`, `load()`, `sync()`, `onRemoteDataApplied: AnyPublisher<Void, Never>`

- [ ] **Step 1: Rewrite Synchronizer.swift**

```swift
import Foundation
import Combine

class Synchronizer {
    var approach: Option {
        didSet {
            guard approach != oldValue else { return }
            Task { await sync() }
        }
    }

    let onRemoteDataApplied: AnyPublisher<Void, Never>
    private let _onRemoteDataApplied = PassthroughSubject<Void, Never>()

    private var cancellables = Set<AnyCancellable>()
    private let providers: [Option: any Provider]
    private let localProvider: LocalStorageProvider
    private let history = History()

    private var remoteProvider: (any Provider)? {
        guard approach != .local else { return nil }
        return providers[approach]
    }

    init(approach: Option, providers: [Option: any Provider], localProvider: LocalStorageProvider) {
        self.approach = approach
        self.providers = providers
        self.localProvider = localProvider
        self.onRemoteDataApplied = _onRemoteDataApplied.eraseToAnyPublisher()
        bind()
    }

    private func bind() {
        localProvider.incoming
            .sink { [weak self] _ in
                self?._onRemoteDataApplied.send(())
            }
            .store(in: &cancellables)

        for (option, provider) in providers where option != .local {
            provider.incoming
                .sink { [weak self] remoteSidecar in
                    guard let self, self.approach == option else { return }
                    Task { await self.handleRemoteIncoming(remoteSidecar) }
                }
                .store(in: &cancellables)
        }
    }

    // MARK: - Public API

    func save(document html: String) {
        do {
            let sidecar = try localProvider.write(html: html)
            history.log(action: "local_edit", sidecar: sidecar)
            guard let remote = remoteProvider else { return }
            Task {
                do {
                    let document = try await localProvider.readDocument()
                    try await remote.send(document: document, sidecar: sidecar)
                    history.log(action: "push_to_\(approach.rawValue)", sidecar: sidecar)
                } catch {
                    print("[Sync] push failed: \(error)")
                }
            }
        } catch {
            print("[Sync] local write failed: \(error)")
        }
    }

    func load() throws -> String {
        let data = try localProvider.readDocumentSync()
        guard let html = String(data: data, encoding: .utf8) else {
            throw SyncError.corruptDocument
        }
        return html
    }

    func sync() async {
        guard let remote = remoteProvider else { return }
        do {
            let availability = await remote.checkAvailability()
            guard availability == .yes else { return }

            let remoteSidecar = try await remote.readSidecar()
            let localSidecar = try localProvider.readSidecarSync()

            if remoteSidecar.timestamp > localSidecar.timestamp {
                let document = try await remote.readDocument()
                try localProvider.send(document: document, sidecar: remoteSidecar)
                history.log(action: "download_from_\(approach.rawValue)", sidecar: remoteSidecar)
            } else if localSidecar.timestamp > remoteSidecar.timestamp {
                let document = try await localProvider.readDocument()
                try await remote.send(document: document, sidecar: localSidecar)
                history.log(action: "push_to_\(approach.rawValue)", sidecar: localSidecar)
            }
        } catch {
            print("[Sync] sync failed: \(error)")
        }
    }

    // MARK: - Private

    private func handleRemoteIncoming(_ remoteSidecar: SidecarData) async {
        do {
            let localSidecar = try localProvider.readSidecarSync()
            guard remoteSidecar.uid != localSidecar.uid else { return }
            guard remoteSidecar.timestamp > localSidecar.timestamp else { return }

            guard let remote = remoteProvider else { return }
            let document = try await remote.readDocument()
            try localProvider.send(document: document, sidecar: remoteSidecar)
            history.log(action: "download_from_\(approach.rawValue)", sidecar: remoteSidecar)
        } catch {
            print("[Sync] remote incoming failed: \(error)")
        }
    }
}

// MARK: - Protocol & Types

extension Synchronizer {
    protocol Provider {
        var incoming: AnyPublisher<SidecarData, Never> { get }
        func readSidecar() async throws -> SidecarData
        func readDocument() async throws -> Data
        func send(document: Data, sidecar: SidecarData) async throws
        func checkAvailability() async -> Availability
        func prepare() async throws
        func pause() async throws
    }

    enum Option: String, CaseIterable, Identifiable {
        var id: String { rawValue }
        case icloud
        case local
        case dropbox
    }

    enum Availability: Equatable {
        static func == (lhs: Availability, rhs: Availability) -> Bool {
            switch (lhs, rhs) {
            case (.yes, .yes): return true
            case (.no, .no): return true
            default: return false
            }
        }
        case yes
        case no(Error?)
    }

    enum SyncError: Error, LocalizedError {
        case corruptDocument
        case corruptSidecar
    }
}

extension Synchronizer.Provider {
    func prepare() async throws {}
    func pause() async throws {}
}
```

- [ ] **Step 2: Verify Synchronizer.swift has no syntax errors**

Run: Cmd+B
Expected: errors only in `LocalStorageProvider`, `AiCloudProvider`, `DropboxProvider` (protocol conformance). `Synchronizer.swift` itself should parse cleanly.

- [ ] **Step 3: Commit**

```bash
git add Stash/Synchronization/Synchronizer.swift
git commit -m "feat: rewrite Synchronizer with new Provider protocol and orchestration"
```

---

### Task 4: LocalStorageProvider

**Files:**
- Rewrite: `Stash/Synchronization/LocalStorageProvider.swift`

**Interfaces:**
- Consumes: `SidecarData`, `Synchronizer.Provider` protocol
- Produces: `LocalStorageProvider` conforming to `Provider`, plus non-protocol methods `write(html:) throws -> SidecarData`, `readSidecarSync() throws -> SidecarData`, `readDocumentSync() throws -> Data`

- [ ] **Step 1: Rewrite LocalStorageProvider.swift**

```swift
import Foundation
import Combine

extension Synchronizer {
    final class LocalStorageProvider: Provider {
        private let _incoming = PassthroughSubject<SidecarData, Never>()
        var incoming: AnyPublisher<SidecarData, Never> { _incoming.eraseToAnyPublisher() }

        private let directory: URL

        init() {
            let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            directory = support.appendingPathComponent("Stash", isDirectory: true)
            if !FileManager.default.fileExists(atPath: directory.path) {
                try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            }
        }

        private var documentURL: URL {
            directory.appendingPathComponent(FileName.document)
        }

        private var sidecarURL: URL {
            directory.appendingPathComponent(FileName.sidecar)
        }

        // MARK: - Protocol conformance

        func readSidecar() async throws -> SidecarData {
            try readSidecarSync()
        }

        func readDocument() async throws -> Data {
            try readDocumentSync()
        }

        func send(document: Data, sidecar: SidecarData) throws {
            let localSidecar = try? readSidecarSync()
            if let localSidecar, localSidecar.uid == sidecar.uid {
                return
            }
            try document.write(to: documentURL, options: .atomic)
            let sidecarData = try JSONEncoder().encode(sidecar)
            try sidecarData.write(to: sidecarURL, options: .atomic)
            _incoming.send(sidecar)
        }

        func checkAvailability() async -> Availability {
            .yes
        }

        // MARK: - Non-protocol (local hub role)

        @discardableResult
        func write(html: String) throws -> SidecarData {
            let sidecar = SidecarData.stamp()
            guard let documentData = html.data(using: .utf8) else {
                throw SyncError.corruptDocument
            }
            try documentData.write(to: documentURL, options: .atomic)
            let sidecarData = try JSONEncoder().encode(sidecar)
            try sidecarData.write(to: sidecarURL, options: .atomic)
            return sidecar
        }

        func readSidecarSync() throws -> SidecarData {
            let data = try Data(contentsOf: sidecarURL)
            return try JSONDecoder().decode(SidecarData.self, from: data)
        }

        func readDocumentSync() throws -> Data {
            try Data(contentsOf: documentURL)
        }
    }
}
```

- [ ] **Step 2: Verify it compiles**

Run: Cmd+B
Expected: `LocalStorageProvider` compiles. Remaining errors only in `AiCloudProvider` and `DropboxProvider`.

- [ ] **Step 3: Commit**

```bash
git add Stash/Synchronization/LocalStorageProvider.swift
git commit -m "feat: rewrite LocalStorageProvider with new protocol and write(html:)"
```

---

### Task 5: AiCloudProvider

**Files:**
- Rewrite: `Stash/Synchronization/AiCloudProvider.swift`

**Interfaces:**
- Consumes: `SidecarData`, `Synchronizer.Provider`, `AiCloudContainerMonitor`
- Produces: `AiCloudProvider` with `incoming` firing parsed `SidecarData` on iCloud file change; `prepare()` starts monitor, `pause()` stops it

- [ ] **Step 1: Rewrite AiCloudProvider.swift**

```swift
import Foundation
import Combine

extension Synchronizer {
    final class AiCloudProvider: Provider {
        private let _incoming = PassthroughSubject<SidecarData, Never>()
        var incoming: AnyPublisher<SidecarData, Never> { _incoming.eraseToAnyPublisher() }

        private let monitor = AiCloudContainerMonitor(filename: FileName.sidecar)
        private var monitorHandle: AnyCancellable?

        init() {}

        deinit {
            stopMonitor()
        }

        // MARK: - Protocol

        func checkAvailability() async -> Availability {
            let available = await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .utility).async {
                    let url = FileManager.default.url(forUbiquityContainerIdentifier: nil)
                    continuation.resume(returning: url != nil)
                }
            }
            return available ? .yes : .no(ProviderError.icloudContainerUnavailable)
        }

        func readSidecar() async throws -> SidecarData {
            let url = try sidecarURL()
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(SidecarData.self, from: data)
        }

        func readDocument() async throws -> Data {
            let url = try documentURL()
            return try Data(contentsOf: url)
        }

        func send(document: Data, sidecar: SidecarData) async throws {
            let docURL = try documentURL()
            let scURL = try sidecarURL()
            try document.write(to: docURL, options: .atomic)
            let sidecarData = try JSONEncoder().encode(sidecar)
            try sidecarData.write(to: scURL, options: .atomic)
        }

        func prepare() async throws {
            startMonitor()
        }

        func pause() async throws {
            stopMonitor()
        }

        // MARK: - Monitor

        private func startMonitor() {
            monitorHandle = monitor.$onChange
                .compactMap { $0 }
                .delay(for: .seconds(2), scheduler: RunLoop.main)
                .sink { [weak self] _ in
                    guard let self else { return }
                    do {
                        let url = try self.sidecarURL()
                        let data = try Data(contentsOf: url)
                        let sidecar = try JSONDecoder().decode(SidecarData.self, from: data)
                        self._incoming.send(sidecar)
                    } catch {
                        print("[iCloud] failed to parse incoming sidecar: \(error)")
                    }
                }
            monitor.start()
        }

        private func stopMonitor() {
            monitor.stop()
            monitorHandle?.cancel()
            monitorHandle = nil
        }

        // MARK: - Paths

        private func containerDocumentsURL() throws -> URL {
            guard let container = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
                throw ProviderError.icloudContainerUnavailable
            }
            let documents = container.appendingPathComponent("Documents")
            if !FileManager.default.fileExists(atPath: documents.path) {
                try FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
            }
            return documents
        }

        private func documentURL() throws -> URL {
            try containerDocumentsURL().appendingPathComponent(FileName.document)
        }

        private func sidecarURL() throws -> URL {
            try containerDocumentsURL().appendingPathComponent(FileName.sidecar)
        }
    }
}

extension Synchronizer.AiCloudProvider {
    enum ProviderError: Error, LocalizedError {
        case icloudContainerUnavailable

        var errorDescription: String? {
            switch self {
            case .icloudContainerUnavailable:
                return "iCloud container is not available"
            }
        }
    }
}
```

- [ ] **Step 2: Verify it compiles**

Run: Cmd+B
Expected: `AiCloudProvider` compiles. Only `DropboxProvider` errors remain.

- [ ] **Step 3: Commit**

```bash
git add Stash/Synchronization/AiCloudProvider.swift
git commit -m "feat: rewrite AiCloudProvider with new protocol and sidecar-based incoming"
```

---

### Task 6: DropboxProvider Stub & Pref Cleanup

**Files:**
- Modify: `Stash/Synchronization/DropboxProvider.swift`
- Modify: `Stash/Helpers/Pref.swift`

**Interfaces:**
- Consumes: `SidecarData`, `Synchronizer.Provider`
- Produces: compiling `DropboxProvider` stub; `Pref.Key.appIdentifier` removed

- [ ] **Step 1: Rewrite DropboxProvider to stub against new protocol**

```swift
import Foundation
import Combine

extension Synchronizer {
    final class DropboxProvider: Provider {
        private let _incoming = PassthroughSubject<SidecarData, Never>()
        var incoming: AnyPublisher<SidecarData, Never> { _incoming.eraseToAnyPublisher() }

        init() {}

        func checkAvailability() async -> Availability {
            .no(ProviderError.notImplemented)
        }

        func readSidecar() async throws -> SidecarData {
            throw ProviderError.notImplemented
        }

        func readDocument() async throws -> Data {
            throw ProviderError.notImplemented
        }

        func send(document: Data, sidecar: SidecarData) async throws {
            throw ProviderError.notImplemented
        }
    }
}

extension Synchronizer.DropboxProvider {
    enum ProviderError: Error, LocalizedError {
        case notImplemented

        var errorDescription: String? {
            switch self {
            case .notImplemented:
                return "Dropbox sync is not yet implemented"
            }
        }
    }
}
```

- [ ] **Step 2: Remove `appIdentifier` from Pref.swift**

In `Stash/Helpers/Pref.swift`, delete the line:

```swift
static let appIdentifier = Entry<String>("appIdentifier")
```

- [ ] **Step 3: Fix any remaining compile errors from `appIdentifier` removal**

Search the project for `Pref.Key.appIdentifier` or `Pref.value(for: Pref.Key.appIdentifier)`. If any references remain, remove them.

Run: Cmd+B
Expected: clean build, zero errors

- [ ] **Step 4: Commit**

```bash
git add Stash/Synchronization/DropboxProvider.swift Stash/Helpers/Pref.swift
git commit -m "feat: stub DropboxProvider, remove obsolete appIdentifier pref key"
```

---

### Task 7: Wire Up App Layer

**Files:**
- Modify: `Stash/AppDelegate.swift`
- Modify: `Stash/ViewModels/HouseKeeper.swift`
- Modify: `Stash/ViewModels/SettingsViewModel.swift`

**Interfaces:**
- Consumes: `Synchronizer` with full API from Tasks 1–6
- Produces: integrated app — edits sync, remote changes reload UI, settings shows provider availability

- [ ] **Step 1: Update AppDelegate initialization**

Replace the current `Synchronizer` init with the new signature. Add `applicationDidBecomeActive` trigger.

```swift
// In AppDelegate or wherever Synchronizer is created:

let localProvider = Synchronizer.LocalStorageProvider()
let icloudProvider = Synchronizer.AiCloudProvider()
let dropboxProvider = Synchronizer.DropboxProvider()

let providers: [Synchronizer.Option: any Synchronizer.Provider] = [
    .local: localProvider,
    .icloud: icloudProvider,
    .dropbox: dropboxProvider,
]

let savedApproach = Pref.value(for: Pref.Key.synchronizerApproach) ?? .local
let synchronizer = Synchronizer(
    approach: savedApproach,
    providers: providers,
    localProvider: localProvider
)

// Prepare the active remote provider
Task {
    if savedApproach != .local, let remote = providers[savedApproach] {
        try? await remote.prepare()
    }
}
```

Add in `applicationDidBecomeActive(_:)`:

```swift
func applicationDidBecomeActive(_ notification: Notification) {
    Task { await synchronizer.sync() }
}
```

- [ ] **Step 2: Update HouseKeeper to use new Synchronizer API**

Replace current save/load calls and subscribe to `onRemoteDataApplied`:

```swift
// In HouseKeeper init or bind method:
synchronizer.onRemoteDataApplied
    .receive(on: RunLoop.main)
    .sink { [weak self] in
        self?.reload()
    }
    .store(in: &cancellables)

// Replace save call (now sync fire-and-forget):
func save(entries: [Entry]) {
    let html = render(entries)
    synchronizer.save(document: html)
}

// load() stays the same signature:
func reload() {
    guard let html = try? synchronizer.load() else { return }
    // parse and update entries...
}
```

- [ ] **Step 3: Update SettingsViewModel with availability check**

```swift
// In SettingsViewModel:

@Published var availability: Synchronizer.Availability?

var onCheckAvailability: ((Synchronizer.Option) async -> Synchronizer.Availability)?

func refreshAvailability() {
    guard let check = onCheckAvailability else { return }
    let current = synchronizerApproach
    Task { @MainActor in
        availability = await check(current)
    }
}
```

Wire in AppDelegate (or wherever SettingsViewModel is created):

```swift
settingsViewModel.onCheckAvailability = { [providers] option in
    guard let provider = providers[option] else { return .no(nil) }
    return await provider.checkAvailability()
}
```

- [ ] **Step 4: Save approach to Pref on change**

In `SettingsViewModel` or wherever `synchronizerApproach` is set:

```swift
var synchronizerApproach: Synchronizer.Option {
    didSet {
        Pref.save(for: Pref.Key.synchronizerApproach, value: synchronizerApproach)
        synchronizer.approach = synchronizerApproach
        refreshAvailability()
    }
}
```

- [ ] **Step 5: Build and verify full compilation**

Run: Cmd+B
Expected: clean build, zero errors, zero warnings related to sync

- [ ] **Step 6: Manual smoke test**

1. Launch app → verify existing bookmarks load (local read path)
2. Edit a bookmark → verify `nustash_index.html` and `.sidecar` update in `~/Library/Application Support/Stash/`
3. Switch to iCloud in settings → verify availability status displays
4. If iCloud available: verify files appear in iCloud container after edit
5. Simulate remote change (manually edit iCloud sidecar with newer timestamp) → verify app reloads

- [ ] **Step 7: Commit**

```bash
git add Stash/AppDelegate.swift Stash/ViewModels/HouseKeeper.swift Stash/ViewModels/SettingsViewModel.swift
git commit -m "feat: wire synchronizer into app layer with reload and availability"
```
