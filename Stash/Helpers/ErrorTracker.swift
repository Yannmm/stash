//
//  ErrorTracker.swift
//  Stash
//
//  Created by Rayman on 2025/5/14.
//

import Combine

class ErrorTracker {
    static let shared = ErrorTracker()
    
    private let tank = PassthroughSubject<SomeError, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        tank
            .sink { [weak self] e in
                self?.handle(e)
            }
            .store(in: &cancellables)
    }
    
    private func handle(_ error: SomeError) {
        print("⚠️ Error Tracked: \(error.error.localizedDescription)")
        if let info = error.info {
            print("ℹ️ Info: \(info)")
        }
        
        // TODO: send firebase or sentry
    }
    
    func add(_ error: Error, _ info: [String: Any]? = nil) {
        let error = SomeError(error: error, info: info)
        tank.send(error)
    }
}

extension ErrorTracker {
    struct SomeError {
        let error: Error
        let info: [String: Any]?
    }
}
