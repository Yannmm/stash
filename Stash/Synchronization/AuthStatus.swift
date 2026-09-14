//
//  AuthStatus.swift
//  Stash
//
//  Created by Yan Meng on 2026/8/23.
//

import Foundation
import SwiftUI

extension Synchronizer {
    enum AuthStatus {
        case anonymous((String) -> Void)
        case ready(String?, (String) -> Void)
        case error(Error, (String) -> Void)
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
        case .error(let e, _):
            var attr = AttributedString("An error happended, please try again: \(e.localizedDescription)")
            attr.foregroundColor = .secondary
            if let range = attr.range(of: "try again") {
                attr[range].foregroundColor = Color(nsColor: .linkColor)
                attr[range].link = URL(string: "error://abc")
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
        }
    }
    
    func action(_ phrase: String) {
        switch self {
        case .anonymous(let action):
            action(phrase)
        case .error(_, let action):
            action(phrase)
        case .ready(_, let action):
            action(phrase)
        }
    }
}
