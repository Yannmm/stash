//
//  AppDelegate+Search.swift
//  Stash
//
//  Created by Yan Meng on 2025/7/17.
//

import AppKit
import SwiftUI

enum Constant1 {
    static var demoMenuItems: [SearchItem] {
        [
            SearchItem(id: UUID(), title: "test1", detail: "this is a good test", icon: .system("star")),
            SearchItem(id: UUID(), title: "test1", detail: "this is a good test", icon: .system("star")),
            SearchItem(id: UUID(), title: "test1", detail: "this is a good test", icon: .system("star")),
            SearchItem(id: UUID(), title: "test1", detail: "this is a good test", icon: .system("star")),
            SearchItem(id: UUID(), title: "test1", detail: "this is a good test", icon: .system("star")),
            SearchItem(id: UUID(), title: "test1", detail: "this is a good test", icon: .system("star")),
            SearchItem(id: UUID(), title: "test1", detail: "this is a good test", icon: .system("star")),
        ]
    }
}

extension AppDelegate {
    @objc func search() {
        MenuManager.shared.show(Constant1.demoMenuItems, anchorRect: statusItemButtonFrame, source: nil)
    }
    
    private var statusItemButtonFrame: NSRect {
        if let button = statusItem?.button,
           let frame = button.window?.convertToScreen(button.convert(button.bounds, to: nil)) {
            return frame
        }
        return .zero
    }
}
