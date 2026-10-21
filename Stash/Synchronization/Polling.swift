//
//  Polling.swift
//  Stash
//
//  Created by Yan Meng on 2026/8/22.
//

import Foundation

extension Synchronizer {
    protocol Polling: AnyObject {
        var poltask: Task<Void, Never>? { get set }
        
        var polinterval: Int { get }
        
        func startpol()
        
        func pausepol()
        
        func poll() async throws
        
        func sidecar() async throws -> Sidecar
        
        func setOnArrive(_ sidecar: Sidecar?)
        
        func onPollError(_ error: Error)
    }
}

extension Synchronizer.Polling {
    var polinterval: Int { 10 }
    
    func startpol() {
        guard poltask == nil else { return }
        poltask = Task { [weak self] in
            var failures = 0
            while !Task.isCancelled {
                guard let self else { return }
                do {
                    try await self.poll()
                    failures = 0
                } catch {
                    failures += 1
                    onPollError(error)
                }
                // Back off on consecutive failures, capped at 32x interval
                let delay = polinterval * (1 << min(failures, 5))
                try? await Task.sleep(for: .seconds(delay))
            }
        }
    }
    
    func pausepol() {
        poltask?.cancel()
        poltask = nil
    }
    
    /// Emits the remote sidecar on every tick (nil if absent), the synchronizer decides whether to pull or push.
    func poll() async throws {
        let sidecar: Sidecar?
        do {
            sidecar = try await self.sidecar()
        } catch Synchronizer.SyncError.fileNotFound {
            sidecar = nil
        }
        setOnArrive(sidecar)
    }
}
