//
//  fff.swift
//  Stash
//
//  Created by Rayman on 2025/7/29.
//

import AppKit
import SwiftUI

class FloatingPanel {
    let anchorRect: NSRect
    let content: AnyView
    let viewModel: SearchViewModel
    init(at anchorRect: NSRect, viewModel: SearchViewModel) {
        self.anchorRect = anchorRect
        self.viewModel = viewModel
        self.content = AnyView(_SearchView(viewModel: viewModel))
    }
    
    private var _panel: FocusablePanel!
    
    func show() {
        close()
        
        let hosting = NSHostingController(rootView: content)
        hosting.view.frame = CGRect(origin: .zero, size: hosting.view.intrinsicContentSize)
        
        _panel = FocusablePanel(
            contentRect: hosting.view.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        //        _panel.level = .statusBar
        _panel.isOpaque = true
        _panel.backgroundColor = NSColor.clear
        _panel.hasShadow = true
        _panel.worksWhenModal = true
        _panel.becomesKeyOnlyIfNeeded = false
        _panel.acceptsMouseMovedEvents = true
        _panel.isFloatingPanel = false
        _panel.hidesOnDeactivate = false
        _panel.isReleasedWhenClosed = false
        _panel.level = .normal
        
        _panel.contentViewController = hosting
        
        let panelSize = hosting.view.intrinsicContentSize // your panel's size
        
        // Position the panel below the status item
        let point = CGPoint(
            x: anchorRect.midX - panelSize.width / 2,
            y: anchorRect.minY - panelSize.height - 5 // 5pt gap below status item
        )
        
        _panel.setFrameOrigin(point)
        //        _panel.orderFront(nil)
        _panel.makeKeyAndOrderFront(nil)
        // TODO: release nspanel
    }
    
    func close() {
        _panel?.close()
        _panel = nil
    }
}
