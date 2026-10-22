//
//  AuthStatus.swift
//  Stash
//
//  Created by Yan Meng on 2026/8/23.
//

import Combine
import Foundation
import SwiftUI

extension Synchronizer {
    protocol ProviderReadiness: Descriptor {
        var ready: Bool { get }
    }
}

extension Publisher where Failure == Never {
    /// Erases a subject's concrete readiness type so providers can expose it
    /// as the `RemoteProvider.readiness` existential stream.
    func eraseToReadinessPublisher<Readiness: Synchronizer.ProviderReadiness>()
        -> AnyPublisher<Result<any Synchronizer.ProviderReadiness, Error>, Never>
        where Output == Result<Readiness, Error> {
        map { result in
            result.map { $0 as any Synchronizer.ProviderReadiness }
        }
        .eraseToAnyPublisher()
    }
}

extension Synchronizer {
    enum UbiquityContainerReachability: ProviderReadiness {
        
        case yes
        case indetermined
        
        func describe() -> AttributedString {
            switch self {
            case .yes:
                var attr = AttributedString("iCloud is ready.")
                attr.foregroundColor = .secondary
                if let range = attr.range(of: "iCloud") {
                    attr[range].foregroundColor = .primary
                }
                return attr
            case .indetermined:
                var attr = AttributedString("iCloud accessbility not determined yet.")
                attr.foregroundColor = .secondary
                if let range = attr.range(of: "iCloud") {
                    attr[range].foregroundColor = .primary
                }
                return attr
            }
        }
        
        var ready: Bool {
            switch self {
            case .yes:
                return true
            case .indetermined:
                return false
            }
        }
    }
}

extension Synchronizer {
    enum AuthStatus: ProviderReadiness {
        case anonymous((String) -> Void)
        case ready(String?, (String) -> Void)
        case initializing(String)
        
        var ready: Bool {
            switch self {
            case .ready(_, _):
                return true
            case .anonymous(_):
                fallthrough
            case .initializing(_):
                return false
            }
        }
    }
}

extension Synchronizer.AuthStatus: Synchronizer.Descriptor {
    func describe() -> AttributedString {
        switch self {
        case .anonymous:
            var attr = AttributedString("Please sign in")
            attr.foregroundColor = .secondary
            if let range = attr.range(of: "sign in") {
                attr[range].foregroundColor = Color(nsColor: .linkColor)
                attr[range].link = URL(string: "signin://abc")
            }
            return attr
        case .ready(let name, _):
            var attr = AttributedString("Already signed-in")
            if let n = name {
                attr = attr + AttributedString(" as \(n)")
            } else {
                attr = attr + AttributedString(" (logout)")
            }
            
            attr.foregroundColor = .secondary
            
            if let n = name, let range = attr.range(of: n) {
                attr[range].foregroundColor = Color(nsColor: .linkColor)
                attr[range].link = URL(string: "logout://abc")
            }
            if let range = attr.range(of: "logout") {
                attr[range].foregroundColor = Color(nsColor: .systemRed)
                attr[range].link = URL(string: "logout://abc")
            }
            
            return attr
        case .initializing(let provider):
            var attr = AttributedString("\(provider) is initializing.")
            attr.foregroundColor = .secondary
            if let range = attr.range(of: provider) {
                attr[range].foregroundColor = .primary
            }
            return attr
        }
    }
    
    func action(_ phrase: String) {
        switch self {
        case .anonymous(let action):
            action(phrase)
        case .initializing(_):
            break // do nothing since it's pending
        case .ready(_, let action):
            action(phrase)
        }
    }
}
