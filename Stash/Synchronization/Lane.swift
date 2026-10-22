//
//  Lane.swift
//  Stash
//

import Foundation

extension Synchronizer {
    /// Serial lane for sync operations, so read-compare-write steps never interleave.
    final class Lane {
        private var tail: Task<Void, Never>?

        private var pendingDroppable = 0

        private let lock = NSLock()

        /// Runs `operation` after all previously enqueued ones finish.
        /// A droppable operation is skipped if another droppable one is already waiting or running.
        func enqueue(droppable: Bool = false, _ operation: @escaping () async -> Void) {
            lock.lock()
            defer { lock.unlock() }
            if droppable {
                guard pendingDroppable == 0 else { return }
                pendingDroppable += 1
            }
            let previous = tail
            tail = Task { [weak self] in
                await previous?.value
                await operation()
                if droppable { self?.finishDroppable() }
            }
        }

        private func finishDroppable() {
            lock.lock()
            pendingDroppable -= 1
            lock.unlock()
        }
    }
}
