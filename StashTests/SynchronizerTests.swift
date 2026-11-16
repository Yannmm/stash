//
//  SynchronizerTests.swift
//  StashTests
//

import Foundation
import Testing
@testable import Nustash

// MARK: - Reconcile rules (poll tick path)

@Suite("Reconcile rules via poll tick")
struct ReconcileRuleTests {

    @Test func bothMissingDoesNothing() async {
        let h = SyncHarness()
        h.remote.tick(nil)
        await h.settle()
        #expect(h.log.mutations().isEmpty)
        #expect(h.local.storedSidecar.value == nil)
        #expect(h.remote.storedSidecar.value == nil)
    }

    @Test func onlyLocalPushes() async {
        let h = SyncHarness()
        let l = makeSidecar(10)
        h.local.seed(l, "local")
        h.remote.tick(nil)
        #expect(await eventually { h.remote.storedSidecar.value == l })
        #expect(h.remote.storedDocument.value == data("local"))
    }

    @Test func onlyRemotePulls() async {
        let h = SyncHarness()
        let r = makeSidecar(10)
        h.remote.seed(r, "remote")
        h.remote.tick()
        #expect(await eventually { h.local.storedSidecar.value == r })
        #expect(h.local.html == "remote")
        #expect(h.changes.value == 1)
    }

    @Test func sameUidDoesNothing() async {
        let h = SyncHarness()
        let s = makeSidecar(10)
        h.local.seed(s, "same")
        h.remote.seed(s, "same")
        h.remote.tick()
        await h.settle()
        #expect(h.log.mutations().isEmpty)
        #expect(!h.log.all.contains("dropbox.document"))
    }

    @Test func remoteNewerPulls() async {
        let h = SyncHarness()
        h.local.seed(makeSidecar(10), "old")
        let r = makeSidecar(20)
        h.remote.seed(r, "new")
        h.remote.tick()
        #expect(await eventually { h.local.storedSidecar.value == r })
        #expect(h.local.html == "new")
    }

    @Test func localNewerPushes() async {
        let h = SyncHarness()
        let l = makeSidecar(20)
        h.local.seed(l, "new")
        h.remote.seed(makeSidecar(10), "old")
        h.remote.tick()
        #expect(await eventually { h.remote.storedSidecar.value == l })
        #expect(h.remote.storedDocument.value == data("new"))
        #expect(h.local.html == "new")
    }

    @Test func timestampTieWithDifferentUidPulls() async {
        let h = SyncHarness()
        h.local.seed(makeSidecar(10), "local")
        let r = makeSidecar(10)
        h.remote.seed(r, "remote")
        h.remote.tick()
        #expect(await eventually { h.local.storedSidecar.value == r })
        #expect(h.local.html == "remote")
    }

    @Test func emptyLocalDocumentIsNotPushed() async {
        let h = SyncHarness()
        let l = makeSidecar(20)
        h.local.seed(l, "")
        h.remote.seed(makeSidecar(10), "remote")
        h.remote.tick()
        await h.settle()
        #expect(h.log.mutations().isEmpty)
        #expect(h.remote.storedDocument.value == data("remote"))
        #expect(h.history.entries.contains { $0.action.contains("skip push") })
    }

    @Test func localSidecarWithoutDocumentIsNotPushed() async {
        let h = SyncHarness()
        h.local.seed(makeSidecar(20), nil)
        h.remote.tick(nil)
        await h.settle()
        #expect(h.log.mutations().isEmpty)
    }

    @Test func emptyRemoteDocumentIsNotPulled() async {
        let h = SyncHarness()
        h.local.seed(makeSidecar(10), "keep me")
        h.remote.seed(makeSidecar(20), "")
        h.remote.tick()
        await h.settle()
        #expect(h.local.html == "keep me")
        #expect(h.log.mutations().isEmpty)
        #expect(h.history.entries.contains { $0.action.contains("skip download") })
    }

    @Test func missingRemoteDocumentSurfacesError() async {
        let h = SyncHarness()
        h.local.seed(makeSidecar(10), "keep me")
        h.remote.seed(makeSidecar(20), nil)
        h.remote.tick()
        #expect(await eventually { h.hasError(containing: "reconcile") })
        #expect(h.local.html == "keep me")
    }

    @Test func pushFailureSurfacesErrorAndKeepsLocal() async {
        let h = SyncHarness()
        h.local.seed(makeSidecar(20), "local")
        h.remote.sendError.value = FakeError(message: "quota exceeded")
        h.remote.tick(nil)
        #expect(await eventually { h.hasError(containing: "quota exceeded") })
        #expect(h.local.html == "local")
        #expect(h.remote.storedSidecar.value == nil)
    }

    @Test func pushFailureIsRetriedOnNextTick() async {
        let h = SyncHarness()
        let l = makeSidecar(20)
        h.local.seed(l, "local")
        h.remote.sendError.value = FakeError(message: "offline")
        h.remote.tick(nil)
        #expect(await eventually { h.log.all.contains("dropbox.sendFailed") })
        h.remote.sendError.value = nil
        h.remote.tick(nil)
        #expect(await eventually { h.remote.storedSidecar.value == l })
    }

    @Test func pullFailureSurfacesErrorAndKeepsLocal() async {
        let h = SyncHarness()
        h.local.seed(makeSidecar(10), "keep me")
        h.remote.seed(makeSidecar(20), "remote")
        h.remote.documentError.value = FakeError(message: "network down")
        h.remote.tick()
        #expect(await eventually { h.hasError(containing: "network down") })
        #expect(h.local.html == "keep me")
    }

    @Test func pushAndPullAreLoggedToHistory() async {
        let h = SyncHarness()
        let r = makeSidecar(10)
        h.remote.seed(r, "remote")
        h.remote.tick()
        #expect(await eventually { h.history.entries.contains { $0.action == "download_from_dropbox" } })

        let l = makeSidecar(30)
        h.local.seed(l, "local")
        h.remote.tick()
        #expect(await eventually { h.history.entries.contains { $0.action == "push_to_dropbox" } })
    }

    @Test func reconcileConvergesWithoutPingPong() async {
        let h = SyncHarness()
        h.local.seed(makeSidecar(20), "local")
        h.remote.seed(makeSidecar(10), "remote")
        h.remote.tick()
        #expect(await eventually { h.log.mutations().count == 1 })
        for _ in 0..<5 {
            h.remote.tick()
            await h.settle(.milliseconds(50))
        }
        #expect(h.log.mutations().count == 1)
    }
}

// MARK: - Readiness path

@Suite("Reconcile on readiness")
struct ReadinessTests {

    @Test func readyFetchesRemoteSidecarAndPulls() async {
        let h = SyncHarness()
        let r = makeSidecar(20)
        h.remote.seed(r, "remote")
        h.local.seed(makeSidecar(10), "local")
        h.remote.setReady(true)
        #expect(await eventually { h.local.storedSidecar.value == r })
        #expect(h.log.all.contains("dropbox.sidecar"))
    }

    @Test func readyPushesWhenRemoteMissing() async {
        let h = SyncHarness()
        let l = makeSidecar(10)
        h.local.seed(l, "local")
        h.remote.setReady(true)
        #expect(await eventually { h.remote.storedSidecar.value == l })
    }

    @Test func readyAtStartupReconciles() async {
        let h = SyncHarness(ready: true)
        let l = makeSidecar(10)
        h.local.seed(l, "local")
        #expect(await eventually { h.remote.storedSidecar.value == l })
    }

    @Test func notReadyDoesNothing() async {
        let h = SyncHarness()
        h.local.seed(makeSidecar(10), "local")
        h.remote.setReady(false)
        await h.settle(.milliseconds(800))
        #expect(h.log.mutations().isEmpty)
        #expect(!h.log.all.contains("dropbox.sidecar"))
    }

    @Test func remoteSidecarErrorSurfaces() async {
        let h = SyncHarness()
        h.local.seed(makeSidecar(10), "local")
        h.remote.sidecarError.value = FakeError(message: "unauthorized")
        h.remote.setReady(true)
        #expect(await eventually { h.hasError(containing: "unauthorized") })
        #expect(h.log.mutations().isEmpty)
    }
}

// MARK: - Approach switching

@Suite("Approach switching")
struct ApproachTests {

    @Test func localApproachIgnoresRemoteTicks() async {
        let h = SyncHarness(approach: .local)
        h.local.seed(makeSidecar(10), "local")
        h.remote.tick(nil)
        h.other.tick(nil)
        await h.settle()
        #expect(h.log.mutations().isEmpty)
    }

    @Test func ticksFromInactiveProviderAreIgnored() async {
        let h = SyncHarness(approach: .dropbox)
        h.other.seed(makeSidecar(50), "baidu")
        h.other.tick()
        await h.settle()
        #expect(h.local.storedSidecar.value == nil)
    }

    @Test func switchingRoutesTicksToNewProvider() async {
        let h = SyncHarness(approach: .dropbox)
        h.sync.setApproach(.baidupan)
        await h.settle(.milliseconds(50))
        let r = makeSidecar(50)
        h.other.seed(r, "baidu")
        h.other.tick()
        #expect(await eventually { h.local.storedSidecar.value == r })

        h.remote.seed(makeSidecar(100), "dropbox")
        h.remote.tick()
        await h.settle()
        #expect(h.local.html == "baidu")
    }

    @Test func reconcileUsesProviderThatEmittedTheTick() async {
        let h = SyncHarness(approach: .dropbox)
        let gate = Gate()
        h.remote.documentGate = gate
        let r = makeSidecar(50)
        h.remote.seed(r, "dropbox")
        h.other.seed(makeSidecar(60), "baidu")
        h.remote.tick()
        #expect(await eventually { h.log.all.contains("dropbox.document") })
        h.sync.setApproach(.baidupan)
        gate.open()
        #expect(await eventually { h.local.storedSidecar.value == r })
        #expect(h.local.html == "dropbox")
        #expect(!h.log.all.contains("baidupan.document"))
    }
}

// MARK: - Save

@Suite("Save")
struct SaveTests {

    @Test func saveWritesLocallyAndPushes() async {
        let h = SyncHarness()
        h.sync.save(document: "<html>1</html>")
        #expect(await eventually { h.remote.storedDocument.value == data("<html>1</html>") })
        #expect(h.local.html == "<html>1</html>")
        #expect(h.remote.storedSidecar.value == h.local.storedSidecar.value)
        #expect(h.history.entries.map(\.action).contains("local_edit"))
    }

    @Test func saveOnLocalApproachOnlyWritesLocally() async {
        let h = SyncHarness(approach: .local)
        h.sync.save(document: "<html>1</html>")
        #expect(await eventually { h.local.html == "<html>1</html>" })
        await h.settle(.milliseconds(100))
        #expect(!h.log.all.contains { $0.hasPrefix("send") })
    }

    @Test func failedSavePushIsRecoveredByNextTick() async {
        let h = SyncHarness()
        h.remote.sendError.value = FakeError(message: "offline")
        h.sync.save(document: "<html>offline edit</html>")
        #expect(await eventually { h.hasError(containing: "offline") })
        #expect(h.remote.storedSidecar.value == nil)

        h.remote.sendError.value = nil
        h.remote.tick()
        #expect(await eventually { h.remote.storedDocument.value == data("<html>offline edit</html>") })
        #expect(h.remote.storedSidecar.value == h.local.storedSidecar.value)
    }

    @Test func failedSavePushIsRecoveredOnReadiness() async {
        let h = SyncHarness()
        h.remote.sendError.value = FakeError(message: "offline")
        h.sync.save(document: "<html>offline edit</html>")
        #expect(await eventually { h.log.all.contains("dropbox.sendFailed") })
        h.remote.sendError.value = nil
        h.remote.setReady(true)
        #expect(await eventually { h.remote.storedDocument.value == data("<html>offline edit</html>") })
    }

    @Test func loadReturnsLocalDocument() async {
        let h = SyncHarness()
        #expect(await h.sync.load() == nil)
        h.local.seed(makeSidecar(), "<html>x</html>")
        #expect(await h.sync.load() == "<html>x</html>")
    }

    @Test func loadWithCorruptDataReturnsNil() async {
        let h = SyncHarness()
        h.local.storedSidecar.value = makeSidecar()
        h.local.storedDocument.value = Data([0xFF, 0xFE, 0xFD])
        #expect(await h.sync.load() == nil)
    }
}

// MARK: - Serialization

@Suite("Serialization")
struct SerializationTests {

    @Test func saveDuringPullIsNotClobbered() async {
        let h = SyncHarness()
        let gate = Gate()
        h.remote.documentGate = gate
        h.local.seed(makeSidecar(10), "old")
        h.remote.seed(makeSidecar(20), "remote")
        h.remote.tick()
        #expect(await eventually { h.log.all.contains("dropbox.document") })

        // User saves while the pull is mid-download
        h.sync.save(document: "user edit")
        await h.settle(.milliseconds(100))
        #expect(!h.log.all.contains { $0.hasPrefix("write") })

        gate.open()
        #expect(await eventually { h.remote.storedDocument.value == data("user edit") })
        #expect(h.local.html == "user edit")
        let order = h.log.mutations().map { $0.prefix(4) }
        #expect(order == ["copy", "writ", "send"])
    }

    @Test func ticksAreDroppedWhileOneIsPending() async {
        let h = SyncHarness()
        let gate = Gate()
        h.remote.documentGate = gate
        h.remote.seed(makeSidecar(20), "remote")
        for _ in 0..<10 { h.remote.tick() }
        await h.settle(.milliseconds(100))
        gate.open()
        await h.settle()
        #expect(h.log.all.filter { $0 == "dropbox.document" }.count == 1)
    }

    @Test func savesAreNeverDropped() async {
        let h = SyncHarness()
        for i in 0..<5 {
            h.local.writeOffset.value = TimeInterval(1_000 + i)
            h.sync.save(document: "v\(i)")
        }
        #expect(await eventually { h.log.all.filter { $0.hasPrefix("send") }.count == 5 })
        #expect(h.remote.storedDocument.value == data("v4"))
    }
}

// MARK: - Lane

@Suite("Lane")
struct LaneTests {

    @Test func runsOperationsInOrderWithoutOverlap() async {
        let lane = Synchronizer.Lane()
        let order = Locked<[Int]>([])
        let running = Locked(0)
        let overlap = Locked(false)
        for i in 0..<20 {
            lane.enqueue {
                running.mutate { $0 += 1 }
                if running.value > 1 { overlap.value = true }
                try? await Task.sleep(for: .milliseconds(2))
                order.mutate { $0.append(i) }
                running.mutate { $0 -= 1 }
            }
        }
        #expect(await eventually { order.value.count == 20 })
        #expect(order.value == Array(0..<20))
        #expect(!overlap.value)
    }

    @Test func dropsDroppableWhilePending() async {
        let lane = Synchronizer.Lane()
        let gate = Gate()
        let ran = Locked(0)
        lane.enqueue(droppable: true) { await gate.wait(); ran.mutate { $0 += 1 } }
        lane.enqueue(droppable: true) { ran.mutate { $0 += 1 } }
        lane.enqueue(droppable: true) { ran.mutate { $0 += 1 } }
        gate.open()
        #expect(await eventually { ran.value == 1 })
        try? await Task.sleep(for: .milliseconds(50))
        #expect(ran.value == 1)
    }

    @Test func acceptsDroppableAgainAfterCompletion() async {
        let lane = Synchronizer.Lane()
        let ran = Locked(0)
        lane.enqueue(droppable: true) { ran.mutate { $0 += 1 } }
        #expect(await eventually { ran.value == 1 })
        try? await Task.sleep(for: .milliseconds(20))
        lane.enqueue(droppable: true) { ran.mutate { $0 += 1 } }
        #expect(await eventually { ran.value == 2 })
    }

    @Test func nonDroppableIsNeverDropped() async {
        let lane = Synchronizer.Lane()
        let gate = Gate()
        let ran = Locked<[String]>([])
        lane.enqueue(droppable: true) { await gate.wait(); ran.mutate { $0.append("tick") } }
        lane.enqueue { ran.mutate { $0.append("save1") } }
        lane.enqueue(droppable: true) { ran.mutate { $0.append("dropped") } }
        lane.enqueue { ran.mutate { $0.append("save2") } }
        gate.open()
        #expect(await eventually { ran.value.count == 3 })
        #expect(ran.value == ["tick", "save1", "save2"])
    }

    @Test func droppableQueuedBehindSaveCounts() async {
        let lane = Synchronizer.Lane()
        let gate = Gate()
        let ran = Locked<[String]>([])
        lane.enqueue { await gate.wait(); ran.mutate { $0.append("save") } }
        lane.enqueue(droppable: true) { ran.mutate { $0.append("tick1") } }
        lane.enqueue(droppable: true) { ran.mutate { $0.append("tick2") } }
        gate.open()
        #expect(await eventually { ran.value.count == 2 })
        try? await Task.sleep(for: .milliseconds(50))
        #expect(ran.value == ["save", "tick1"])
    }
}

// MARK: - Polling

@Suite("Polling")
struct PollingTests {

    @Test func pollEmitsSidecarEveryTickEvenIfUnchanged() async throws {
        let p = FakePoller()
        let s = makeSidecar()
        p.result.value = .success(s)
        try await p.poll()
        try await p.poll()
        #expect(p.arrivals.value == [s, s])
    }

    @Test func pollEmitsNilWhenRemoteSidecarMissing() async throws {
        let p = FakePoller()
        p.result.value = .failure(SyncError.fileNotFound("sidecar"))
        try await p.poll()
        #expect(p.arrivals.value.count == 1)
        #expect(p.arrivals.value.first! == nil)
    }

    @Test func pollRethrowsOtherErrors() async {
        let p = FakePoller()
        p.result.value = .failure(FakeError(message: "boom"))
        await #expect(throws: FakeError.self) { try await p.poll() }
        #expect(p.arrivals.value.isEmpty)
    }

    @Test func loopTicksRepeatedly() async {
        let p = FakePoller()
        p.result.value = .success(makeSidecar())
        p.startpol()
        #expect(await eventually { p.arrivals.value.count >= 3 })
        p.pausepol()
    }

    @Test func pauseStopsLoop() async {
        let p = FakePoller()
        p.result.value = .success(makeSidecar())
        p.startpol()
        #expect(await eventually { p.calls.value >= 1 })
        p.pausepol()
        #expect(p.poltask == nil)
        try? await Task.sleep(for: .milliseconds(100))
        let n = p.calls.value
        try? await Task.sleep(for: .milliseconds(150))
        #expect(p.calls.value == n)
    }

    @Test func startIsIdempotent() async {
        let p = FakePoller()
        p.startpol()
        let t = p.poltask
        p.startpol()
        #expect(p.poltask == t)
        p.pausepol()
    }

    @Test func canRestartAfterPause() async {
        let p = FakePoller()
        p.result.value = .success(makeSidecar())
        p.startpol()
        p.pausepol()
        let n = p.calls.value
        p.startpol()
        #expect(await eventually { p.calls.value > n })
        p.pausepol()
    }

    @Test func errorsBackOffInsteadOfHotLooping() async {
        let p = FakePoller()
        p.result.value = .failure(FakeError(message: "offline"))
        p.startpol()
        try? await Task.sleep(for: .milliseconds(500))
        p.pausepol()
        // Delays 40, 80, 160, 320ms... a hot loop would be thousands of calls
        #expect(p.calls.value >= 2)
        #expect(p.calls.value <= 5)
        #expect(p.errors.value.count == p.calls.value)
    }

    @Test func successResetsBackoff() async {
        let p = FakePoller()
        p.result.value = .failure(FakeError(message: "offline"))
        p.startpol()
        #expect(await eventually { p.errors.value.count >= 3 })
        p.result.value = .success(makeSidecar())
        #expect(await eventually { p.arrivals.value.count >= 1 })
        let n = p.calls.value
        try? await Task.sleep(for: .milliseconds(150))
        p.pausepol()
        // At the base 20ms interval, expect several more ticks
        #expect(p.calls.value - n >= 3)
    }

    @Test func missingSidecarIsNotAnError() async {
        let p = FakePoller()
        p.startpol()
        #expect(await eventually { p.arrivals.value.count >= 2 })
        p.pausepol()
        #expect(p.errors.value.isEmpty)
    }
}

// MARK: - History

@Suite("History")
struct HistoryTests {

    private func tempURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("history_\(UUID().uuidString).json")
    }

    @Test func persistsAndReloads() {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }
        let h1 = Synchronizer.History(fileURL: url)
        h1.log(action: "a", sidecar: makeSidecar())
        h1.log(action: "b", sidecar: makeSidecar())
        let h2 = Synchronizer.History(fileURL: url)
        #expect(h2.entries.map(\.action) == ["a", "b"])
    }

    @Test func capsAt100Entries() {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }
        let h = Synchronizer.History(fileURL: url)
        for i in 0..<120 { h.log(action: "\(i)", sidecar: makeSidecar()) }
        #expect(h.entries.count == 100)
        #expect(h.entries.first?.action == "20")
        #expect(h.entries.last?.action == "119")
    }

    @Test func corruptFileStartsEmpty() throws {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }
        try Data("not json".utf8).write(to: url)
        #expect(Synchronizer.History(fileURL: url).entries.isEmpty)
    }
}

// MARK: - SyncError

@Suite("SyncError")
struct SyncErrorTests {

    @Test func descriptionDoesNotRecurse() {
        let e: Error = SyncError.fileNotFound("x")
        #expect(e.localizedDescription.contains("fileNotFound"))
        #expect(SyncError.api(FakeError(message: "inner")).localizedDescription == "inner")
    }
}

// MARK: - Retry

@Suite("Manual retry")
struct RetryTests {

    @Test func errorOffersRetryLink() async {
        let h = SyncHarness()
        h.local.seed(makeSidecar(20), "local")
        h.remote.sendError.value = FakeError(message: "offline")
        h.remote.tick(nil)
        #expect(await eventually { h.hasError(containing: "offline") })
        #expect(h.hasError(containing: "Retry"))
    }

    @Test func noRetryLinkWithoutError() async {
        let h = SyncHarness(ready: true)
        await h.settle(.milliseconds(800))
        #expect(!h.hasError(containing: "Retry"))
    }

    @Test func retryRestartsProviderAndPushes() async {
        let h = SyncHarness()
        let l = makeSidecar(20)
        h.local.seed(l, "local")
        h.remote.sendError.value = FakeError(message: "offline")
        h.remote.tick(nil)
        #expect(await eventually { h.hasError(containing: "offline") })

        h.remote.sendError.value = nil
        h.remote.readyOnPrepare.value = true
        h.sync.retry()
        #expect(await eventually { h.remote.storedSidecar.value == l })
        let ops = h.log.all
        #expect(ops.lastIndex(of: "dropbox.pause")! < ops.lastIndex(of: "dropbox.prepare")!)
        #expect(await eventually { h.descriptions.value.last.map { !$0.contains("offline") } ?? false })
    }

    @Test func retryRecoversFromReadinessFailure() async {
        let h = SyncHarness()
        let l = makeSidecar(20)
        h.local.seed(l, "local")
        h.remote.setNotReady(FakeError(message: "unreachable"))
        #expect(await eventually { h.hasError(containing: "unreachable") })
        #expect(h.hasError(containing: "Retry"))

        h.remote.readyOnPrepare.value = true
        h.sync.retry()
        #expect(await eventually { h.remote.storedSidecar.value == l })
    }

    @Test func retryClearsStrayError() async {
        let h = SyncHarness()
        h.remote.strayError("dropbox poll", FakeError(message: "timeout"))
        #expect(await eventually { h.hasError(containing: "timeout") })

        h.sync.retry()
        #expect(await eventually { h.descriptions.value.last.map { !$0.contains("timeout") } ?? false })
    }

    @Test func retryFailureSurfacesError() async {
        let h = SyncHarness()
        h.remote.prepareError.value = FakeError(message: "still down")
        h.sync.retry()
        #expect(await eventually { h.hasError(containing: "retry dropbox") })
        #expect(h.hasError(containing: "still down"))
    }

    @Test func healthyTickClearsStrayError() async {
        let h = SyncHarness()
        h.remote.strayError("dropbox poll", FakeError(message: "timeout"))
        #expect(await eventually { h.hasError(containing: "timeout") })

        h.remote.tick(nil)
        #expect(await eventually { h.descriptions.value.last.map { !$0.contains("timeout") } ?? false })
    }

    @Test func healthyTickClearsRecoveredPushError() async {
        let h = SyncHarness()
        let l = makeSidecar(20)
        h.local.seed(l, "local")
        h.remote.sendError.value = FakeError(message: "offline")
        h.remote.tick(nil)
        #expect(await eventually { h.hasError(containing: "offline") })

        h.remote.sendError.value = nil
        h.remote.tick(nil)
        #expect(await eventually { h.remote.storedSidecar.value == l })
        #expect(await eventually { h.descriptions.value.last.map { !$0.contains("offline") } ?? false })
    }

    @Test func failingTickKeepsError() async {
        let h = SyncHarness()
        h.local.seed(makeSidecar(20), "local")
        h.remote.sendError.value = FakeError(message: "quota exceeded")
        h.remote.tick(nil)
        #expect(await eventually { h.hasError(containing: "quota exceeded") })
        let n = h.descriptions.value.count

        h.remote.tick(nil)
        #expect(await eventually { h.log.all.filter { $0 == "dropbox.sendFailed" }.count == 2 })
        await h.settle()
        // Never cleared in between, so no flicker
        #expect(h.descriptions.value.dropFirst(n - 1).allSatisfy { $0.contains("quota exceeded") })
    }

    @Test func retryOnLocalIsNoop() async {
        let h = SyncHarness(approach: .local)
        h.sync.retry()
        await h.settle()
        #expect(!h.log.all.contains("dropbox.pause"))
    }
}

// MARK: - Two devices

@Suite("Two devices sharing a remote")
struct TwoDeviceTests {

    // A single FakeRemote is shared, so both synchronizers see the same storage and ticks.
    
    private func device(remote: FakeRemote) -> (Synchronizer, FakeLocal) {
        let local = FakeLocal(log: remote.log)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("h_\(UUID().uuidString).json")
        let s = Synchronizer(approach: .dropbox, remoteProviders: [.dropbox: remote], localProvider: local, history: .init(fileURL: url))
        return (s, local)
    }

    @Test func editOnOneDeviceReachesTheOther() async {
        let remote = FakeRemote(name: "dropbox", log: OpLog())
        let (syncA, localA) = device(remote: remote)
        let (syncB, localB) = device(remote: remote)
        defer { withExtendedLifetime((syncA, syncB)) {} }

        localA.writeOffset.value = 100
        syncA.save(document: "from A")
        #expect(await eventually { remote.storedDocument.value == data("from A") })

        remote.tick()
        #expect(await eventually { localB.html == "from A" })
        #expect(localB.storedSidecar.value == localA.storedSidecar.value)
    }

    @Test func offlineEditPushedAfterReconnectThenOtherPulls() async {
        let remote = FakeRemote(name: "dropbox", log: OpLog())
        let (syncA, localA) = device(remote: remote)
        let (syncB, localB) = device(remote: remote)
        defer { withExtendedLifetime((syncA, syncB)) {} }

        remote.sendError.value = FakeError(message: "offline")
        localA.writeOffset.value = 100
        syncA.save(document: "offline A")
        #expect(await eventually { remote.log.all.contains("dropbox.sendFailed") })

        remote.sendError.value = nil
        remote.tick()
        // A pushes on this tick, B picks it up on the next one
        #expect(await eventually { remote.storedDocument.value == data("offline A") })
        remote.tick()
        #expect(await eventually { localB.html == "offline A" })
    }

    @Test func concurrentEditsLastWriterWins() async {
        let remote = FakeRemote(name: "dropbox", log: OpLog())
        let (syncA, localA) = device(remote: remote)
        let (syncB, localB) = device(remote: remote)
        defer { withExtendedLifetime((syncA, syncB)) {} }

        // Both edit while offline, B's clock is later
        remote.sendError.value = FakeError(message: "offline")
        localA.writeOffset.value = 100
        localB.writeOffset.value = 200
        syncA.save(document: "A")
        syncB.save(document: "B")
        #expect(await eventually { remote.log.all.filter { $0 == "dropbox.sendFailed" }.count == 2 })

        remote.sendError.value = nil
        for _ in 0..<4 {
            remote.tick()
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(100))
        }
        #expect(await eventually { localA.html == "B" && localB.html == "B" })
        #expect(remote.storedDocument.value == data("B"))
    }
}
