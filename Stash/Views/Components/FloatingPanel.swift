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
    private var _panel: FocusablePanel!
    
    private lazy var outsideClickMonitor: OutsideClickMonitor = {
        OutsideClickMonitor { [weak self] in
            self?._panel?.frame ?? .zero
        } onClose: { [weak self] in
            self?.close()
        }
    }()
    
    init(at anchorRect: NSRect, viewModel: SearchViewModel) {
        self.anchorRect = anchorRect
        self.viewModel = viewModel
        self.content = AnyView(
            _SearchView(viewModel: viewModel)
        )
    }
    
    func show() {
        close()
        
        let host = DraggableHostingView(rootView: content)
        host.frame = CGRect(origin: .zero, size: host.intrinsicContentSize)

        
        _panel = FocusablePanel(
            contentRect: host.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        _panel.hasShadow = true
        _panel.worksWhenModal = true
        _panel.becomesKeyOnlyIfNeeded = false
        _panel.acceptsMouseMovedEvents = true
        _panel.isFloatingPanel = false
        _panel.hidesOnDeactivate = false
        _panel.isReleasedWhenClosed = false
        _panel.level = .floating
        
        _panel.isMovableByWindowBackground = false // handled manually now
        _panel.titleVisibility = .hidden
        _panel.titlebarAppearsTransparent = true
        _panel.isOpaque = false
        _panel.backgroundColor = .clear
        
        _panel.contentView = host
        
        let panelSize = host.intrinsicContentSize // your panel's size
        
        // Position the panel below the status item
        let point = CGPoint(
            x: anchorRect.midX - panelSize.width / 2,
            y: anchorRect.minY - panelSize.height - 5 // 5pt gap below status item
        )
        
        _panel.setFrameOrigin(point)
        //        _panel.orderFront(nil)
        _panel.makeKeyAndOrderFront(nil)
        // TODO: release nspanel
        
        outsideClickMonitor.start()
        // TODO: stop when other way to dismiss panel, like type esc
    }
    
    func close() {
        outsideClickMonitor.stop()
        _panel?.close()
        _panel = nil
    }
    
    deinit {
        close()
    }
}
