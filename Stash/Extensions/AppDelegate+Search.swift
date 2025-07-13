//
//  AppDelegate+Search.swift
//  Stash
//
//  Created by Yan Meng on 2025/7/13.
//

import AppKit
import SwiftUI

extension AppDelegate {
    func showSearchPanel() {
        hideSearchPanel()
        
        // Get status item button screen coordinates
        guard let statusButton = statusItem?.button,
              let buttonWindow = statusButton.window else { return }
        
        let buttonFrame = statusButton.frame
        let buttonScreenFrame = buttonWindow.convertToScreen(buttonFrame)
        
        let width: CGFloat = 200
        let height: CGFloat = 150
        
        // Get screen bounds to check available space
        let screenFrame = NSScreen.main?.frame ?? NSRect.zero
        
        // Calculate available space below and above the status button
        let spaceBelow = buttonScreenFrame.origin.y - screenFrame.minY
        let spaceAbove = screenFrame.maxY - buttonScreenFrame.origin.y
        
        // Determine whether to position panel above or below button
        let above = spaceBelow < height && spaceAbove >= height
        
        let y: CGFloat
        if above {
            // Position above button
            y = buttonScreenFrame.origin.y + buttonScreenFrame.height
        } else {
            // Position below button (default behavior)
            y = buttonScreenFrame.origin.y - height
        }
        
        // Center horizontally relative to status button
        let x = buttonScreenFrame.origin.x + (buttonScreenFrame.width - width) / 2
        
        let contentRect = NSRect(
            x: x,
            y: y,
            width: width,
            height: height
        )
        
        panel = NSPanel(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.level = .statusBar
        panel.isOpaque = true
        panel.backgroundColor = NSColor.clear
        panel.hasShadow = true
        panel.worksWhenModal = true
        panel.becomesKeyOnlyIfNeeded = false
        panel.acceptsMouseMovedEvents = true
        
//        panel.contentViewController = NSHostingController(rootView: HashtagSuggestionListView(index: parent.$suggestionIndex, onTap: { [weak self] hashtag in
//            self?._insert(hashtag, textField)
//            self?.hide()
//        }).environmentObject(parent.viewModel))
        panel.contentViewController = NSHostingController(rootView: 
            Button("Click Me") {
                print("hello")
            }
            .buttonStyle(.borderedProminent)
        )
        panel.orderFront(nil)
    }
    
    func hideSearchPanel() {
        panel?.close()
        panel = nil
    }
}
