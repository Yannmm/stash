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
        case anonymous(() -> Void)
        case ready(String?, () -> Void)
        case error(Error, () -> Void)
    }
}

extension Synchronizer.AuthStatus: Synchronizer.Descriptor {
    func describe() -> AttributedString {
        switch self {
        case .anonymous:
            var attr = AttributedString("Please sign in.")
            attr.foregroundColor = .secondary
            if let range = attr.range(of: "sign in") {
                attr[range].foregroundColor = Color.theme
                attr[range].link = URL(string: "action://abc")
            }
            return attr
        case .error(let e, _):
            var attr = AttributedString("An error happended, please try again: \(e.localizedDescription)")
            attr.foregroundColor = .secondary
            if let range = attr.range(of: "try again") {
                attr[range].foregroundColor = Color.theme
                attr[range].link = URL(string: "action://abc")
            }
            return attr
        case .ready(let name, _):
            var attr = AttributedString("Already signed-in")
            if let n = name {
                attr = attr + AttributedString(" as \(n)")
            }
            attr = attr + AttributedString(" (logout)")
            attr.foregroundColor = .secondary
            if let n = name, let range = attr.range(of: n) {
                attr[range].foregroundColor = Color.theme
            }
            if let range = attr.range(of: "logout") {
                attr[range].foregroundColor = Color.red
                attr[range].link = URL(string: "action://abc")
            }
            
            return attr
        }
    }
    
    func action(_ phrase: String) {
        switch self {
        case .anonymous(let action):
            action()
        case .error(_, let action):
            action()
        case .ready(_, let action):
            action()
        }
    }
}
