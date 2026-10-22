//
//  SynchronizerFakes.swift
//  StashTests
//

import Combine
import Foundation
@testable import Nustash

typealias SyncError = Synchronizer.SyncError

// MARK: - Helpers

func makeSidecar(_ offset: TimeInterval = 0, uid: UUID = UUID(), base: Date = Date(timeIntervalSince1970: 1_000_000)) -> Sidecar {
    Sidecar(uid: uid, timestamp: base.addingTimeInterval(offset), prettyTimestamp: nil, device: "test")
}

func data(_ s: String) -> Data { Data(s.utf8) }

/// Polls `condition` until true or timeout.
@discardableResult
func eventually(timeout: Duration = .seconds(3), _ condition: @escaping () -> Bool) async -> Bool {
    let clock = ContinuousClock()
    let deadline = clock.now + timeout
    while clock.now < deadline {
        if condition() { return true }
        try? await Task.sleep(for: .milliseconds(10))
    }
    return condition()
}

final class Locked<Value>: @unchecked Sendable {
    private var _value: Value
    private let lock = NSLock()

    init(_ value: Value) { _value = value }

    var value: Value {
        get { lock.lock(); defer { lock.unlock() }; return _value }
        set { lock.lock(); _value = newValue; lock.unlock() }
    }

    func mutate(_ body: (inout Value) -> Void) {
        lock.lock(); body(&_value); lock.unlock()
    }
}

/// Shared operation log so ordering across providers can be asserted.
final class OpLog: @unchecked Sendable {
    private let ops = Locked<[String]>([])

    var all: [String] { ops.value }

    func record(_ op: String) { ops.mutate { $0.append(op) } }

    func mutations() -> [String] { all.filter { $0.hasPrefix("send") || $0.hasPrefix("copy") || $0.hasPrefix("write") } }
}

/// Async gate: `wait()` suspends until `open()`.
final class Gate: @unchecked Sendable {
    private let lock = NSLock()
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        await withCheckedContinuation { c in
            lock.lock()
            if isOpen {
                lock.unlock()
                c.resume()
            } else {
                waiters.append(c)
                lock.unlock()
            }
        }
    }

    func open() {
        lock.lock()
        isOpen = true
        let w = waiters
        waiters.removeAll()
        lock.unlock()
        w.forEach { $0.resume() }
    }
}

struct FakeReadiness: Synchronizer.ProviderReadiness {
    let ready: Bool
    func describe() -> AttributedString { AttributedString(ready ? "ready" : "not ready") }
}

struct FakeError: Error, LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

// MARK: - Remote

final class FakeRemote: Synchronizer.RemoteProvider, @unchecked Sendable {
    let name: String
    let log: OpLog

    let storedSidecar = Locked<Sidecar?>(nil)
    let storedDocument = Locked<Data?>(nil)
    let sidecarError = Locked<Error?>(nil)
    let documentError = Locked<Error?>(nil)
    let sendError = Locked<Error?>(nil)
    var documentGate: Gate?

    private let _readiness: CurrentValueSubject<Result<any Synchronizer.ProviderReadiness, Error>, Never>
    private let _onArrive = PassthroughSubject<Sidecar?, Never>()
    private let _strayError = PassthroughSubject<(String, Error)?, Never>()

    init(name: String = "remote", log: OpLog, ready: Bool = false) {
        self.name = name
        self.log = log
        _readiness = CurrentValueSubject(.success(FakeReadiness(ready: ready)))
    }

    var readiness: AnyPublisher<Result<any Synchronizer.ProviderReadiness, Error>, Never> { _readiness.eraseToAnyPublisher() }

    var strayError: AnyPublisher<(String, Error)?, Never> { _strayError.eraseToAnyPublisher() }

    var onArrive: AnyPublisher<Sidecar?, Never> { _onArrive.eraseToAnyPublisher() }

    /// Simulates a poll tick reporting the current remote sidecar.
    func tick() { _onArrive.send(storedSidecar.value) }

    func tick(_ sidecar: Sidecar?) { _onArrive.send(sidecar) }

    func setReady(_ flag: Bool) { _readiness.send(.success(FakeReadiness(ready: flag))) }

    func seed(_ sidecar: Sidecar?, _ document: String?) {
        storedSidecar.value = sidecar
        storedDocument.value = document.map(data)
    }

    func sidecar() async throws -> Sidecar {
        log.record("\(name).sidecar")
        if let e = sidecarError.value { throw e }
        guard let s = storedSidecar.value else { throw SyncError.fileNotFound("sidecar") }
        return s
    }

    func document() async throws -> Data {
        log.record("\(name).document")
        await documentGate?.wait()
        if let e = documentError.value { throw e }
        guard let d = storedDocument.value else { throw SyncError.fileNotFound("document") }
        return d
    }

    func send(document: Data, sidecar: Sidecar) async throws {
        if let e = sendError.value {
            log.record("\(name).sendFailed")
            throw e
        }
        log.record("send(\(name),\(sidecar.uid))")
        storedDocument.value = document
        storedSidecar.value = sidecar
    }
}

// MARK: - Local

final class FakeLocal: Synchronizer.LocalProvider, @unchecked Sendable {
    let log: OpLog

    let storedSidecar = Locked<Sidecar?>(nil)
    let storedDocument = Locked<Data?>(nil)
    let writeOffset = Locked<TimeInterval>(1_000)

    private let _onArrive = PassthroughSubject<Sidecar, Never>()

    init(log: OpLog) { self.log = log }

    var onArrive: AnyPublisher<Sidecar, Never> { _onArrive.eraseToAnyPublisher() }

    func seed(_ sidecar: Sidecar?, _ document: String?) {
        storedSidecar.value = sidecar
        storedDocument.value = document.map(data)
    }

    var html: String? { storedDocument.value.flatMap { String(data: $0, encoding: .utf8) } }

    func sidecar() async throws -> Sidecar {
        guard let s = storedSidecar.value else { throw SyncError.fileNotFound("local sidecar") }
        return s
    }

    func document() async throws -> Data {
        guard let d = storedDocument.value else { throw SyncError.fileNotFound("local document") }
        return d
    }

    func copy(document: Data, sidecar: Sidecar) async throws {
        log.record("copy(\(sidecar.uid))")
        storedDocument.value = document
        storedSidecar.value = sidecar
        _onArrive.send(sidecar)
    }

    func write(html: String) throws -> Sidecar {
        let s = makeSidecar(writeOffset.value)
        log.record("write(\(s.uid))")
        storedDocument.value = data(html)
        storedSidecar.value = s
        return s
    }
}

// MARK: - Harness

final class SyncHarness {
    let log = OpLog()
    let local: FakeLocal
    let remote: FakeRemote
    let other: FakeRemote
    let history: Synchronizer.History
    let sync: Synchronizer
    let historyURL: URL

    let descriptions = Locked<[String]>([])
    let changes = Locked(0)
    private var cancellables = Set<AnyCancellable>()

    /// `remote` is registered as dropbox, `other` as baidupan.
    init(approach: Synchronizer.Option = .dropbox, ready: Bool = false) {
        local = FakeLocal(log: log)
        remote = FakeRemote(name: "dropbox", log: log, ready: ready)
        other = FakeRemote(name: "baidupan", log: log, ready: false)
        historyURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("sync_history_\(UUID().uuidString).json")
        history = Synchronizer.History(fileURL: historyURL)
        sync = Synchronizer(
            approach: approach,
            remoteProviders: [.dropbox: remote, .baidupan: other],
            localProvider: local,
            history: history
        )
        sync.description
            .sink { [descriptions] attr in
                descriptions.mutate { $0.append(attr.map { String($0.characters) } ?? "") }
            }
            .store(in: &cancellables)
        sync.onChange
            .sink { [changes] in changes.mutate { $0 += 1 } }
            .store(in: &cancellables)
    }

    func hasError(containing text: String) -> Bool {
        descriptions.value.contains { $0.contains(text) }
    }

    /// Gives queued work a chance to run, for asserting that nothing happened.
    func settle(_ duration: Duration = .milliseconds(300)) async {
        try? await Task.sleep(for: duration)
    }

    deinit {
        try? FileManager.default.removeItem(at: historyURL)
    }
}

// MARK: - Poller

final class FakePoller: Synchronizer.Polling, @unchecked Sendable {
    var poltask: Task<Void, Never>?

    var polinterval: Duration { .milliseconds(20) }

    let result = Locked<Result<Sidecar, Error>>(.failure(SyncError.fileNotFound("sidecar")))
    let arrivals = Locked<[Sidecar?]>([])
    let errors = Locked<[String]>([])
    let calls = Locked(0)

    func sidecar() async throws -> Sidecar {
        calls.mutate { $0 += 1 }
        return try result.value.get()
    }

    func setOnArrive(_ sidecar: Sidecar?) { arrivals.mutate { $0.append(sidecar) } }

    func onPollError(_ error: Error) { errors.mutate { $0.append(error.localizedDescription) } }
}
