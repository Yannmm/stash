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
        func action(_ phrase: String)
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
    func action(_ phrase: String) {
        // noop
    }
}

extension String: Synchronizer.Descriptor {
    func describe() -> AttributedString { AttributedString(self) }
}

extension AttributedString: Synchronizer.Descriptor {
    func describe() -> AttributedString { self }
}
