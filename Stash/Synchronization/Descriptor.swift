//
//  Descriptor.swift
//  Stash
//
//  Created by Yan Meng on 2026/8/22.
//

import Foundation

extension Synchronizer {
    protocol Descriptor {
        func describe() -> AttributedString
        /// Handles a `Link` embedded in `describe()`, ignored if it doesn't apply to this state.
        func action(_ link: Link)
    }
    
    /// Actions embedded as links in a description, routed back through `Synchronizer.perform(_:)`.
    enum Link: String {
        case signin
        case logout
        case retry
        
        private static let scheme = "stash-sync"
        
        var url: URL { URL(string: "\(Self.scheme)://\(rawValue)")! }
        
        init?(url: URL) {
            guard url.scheme == Self.scheme, let host = url.host, let link = Link(rawValue: host) else { return nil }
            self = link
        }
    }
    
    struct InitialPendingState: Descriptor {
        let name: String
        
        func describe() -> AttributedString {
            var attr = AttributedString("\(name) is initializing.")
            if let range = attr.range(of: name) {
                attr[range].foregroundColor = .primary
            }
            return attr
        }
    }
}

extension Synchronizer.Descriptor {
    func action(_ link: Synchronizer.Link) {
        // noop
    }
}

extension String: Synchronizer.Descriptor {
    func describe() -> AttributedString { AttributedString(self) }
}

extension AttributedString: Synchronizer.Descriptor {
    func describe() -> AttributedString { self }
}
