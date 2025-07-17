//
//  AppDelegate+Search.swift
//  Stash
//
//  Created by Yan Meng on 2025/7/17.
//

import AppKit
import SwiftUI

extension AppDelegate {
    @objc func search() {
        setupSearchPanel()
    }
    
    internal func setupSearchPanel() {
        let contentRect = NSRect(
            x: 1000,
            y: 1000,
            width: 1000,
            height: 1000
        )
        
        searchPanel = NSPanel(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        searchPanel.level = .statusBar
        searchPanel.isOpaque = true
        searchPanel.backgroundColor = NSColor.clear
        searchPanel.hasShadow = true
        searchPanel.worksWhenModal = true
        searchPanel.becomesKeyOnlyIfNeeded = false
        searchPanel.acceptsMouseMovedEvents = true
        
        searchPanel.contentViewController = NSHostingController(rootView: CustomMenuDemo())
        searchPanel.orderFront(nil)
    }
}
