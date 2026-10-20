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
        
        var polanchor: UUID? { get set }
        
        func startpol()
        
        func pausepol()
        
        func poll() async throws
        
        func sidecar() async throws -> Sidecar
        
        func setOnArrive(_ sidecar: Sidecar)
        
        func onPollError(_ error: Error)
    }
}

extension Synchronizer.Polling {
    var polinterval: Int { 10 }
    
    func startpol() {
        guard poltask == nil else { return }
        poltask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                do {
                    try await self.poll()
                    try await Task.sleep(for: .seconds(polinterval))
                } catch {
                    onPollError(error)
                }
            }
        }
    }
    
    func pausepol() {
        poltask?.cancel()
        poltask = nil
    }
    
    func poll() async throws {
        let sidecar = try await sidecar()
        guard let a = polanchor,
              sidecar.uid != a else { return }
        polanchor = sidecar.uid
        setOnArrive(sidecar)
    }
}

