//
//  StashTests.swift
//  StashTests
//
//  Created by Yan Meng on 2025/1/28.
//

import Testing
@testable import Stash

struct StashTests {
    @Test func payloadStoreRoundTripsEntries() throws {
        let groupID = UUID()
        let bookmarkID = UUID()
        let entries: [any Entry] = [
            Group(id: groupID, name: "Inbox", parentId: nil, hashtags: nil),
            Bookmark(
                id: bookmarkID,
                name: "Cursor",
                parentId: groupID,
                url: URL(string: "https://cursor.com")!,
                hashtags: nil
            )
        ]

        let store = StashPayloadStore()
        let data = try store.serialize(entries: entries)
        let restored = try store.deserializeEntries(from: data)

        #expect(restored.count == 2)
        #expect(restored.groups.first?.name == "Inbox")
        #expect(restored.bookmarks.first?.name == "Cursor")
        #expect(restored.bookmarks.first?.url.absoluteString == "https://cursor.com")
    }

    @Test func syncPlannerDetectsConflictWhenBothSidesChanged() {
        let checkpoint = SyncCheckpoint(
            method: .baiduDisk,
            contentHash: "old",
            revision: "r1",
            updatedAt: .now
        )

        let decision = SyncPlanner.decide(
            .init(
                localHash: "local-new",
                localIsEmpty: false,
                remoteHash: "remote-new",
                remoteRevision: "r2",
                checkpoint: checkpoint
            )
        )

        #expect(decision == .conflict)
    }

    @Test func syncPlannerDownloadsWhenOnlyRemoteAdvanced() {
        let checkpoint = SyncCheckpoint(
            method: .icloud,
            contentHash: "same-as-local",
            revision: "r1",
            updatedAt: .now
        )

        let decision = SyncPlanner.decide(
            .init(
                localHash: "same-as-local",
                localIsEmpty: false,
                remoteHash: "remote-new",
                remoteRevision: "r2",
                checkpoint: checkpoint
            )
        )

        #expect(decision == .download)
    }
}
