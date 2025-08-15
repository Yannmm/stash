//
//  fff.swift
//  Stash
//
//  Created by Rayman on 2025/7/29.
//

import AppKit
import SwiftUI

class FloatingPanel {
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
    
    init(viewModel: SearchViewModel) {
        self.viewModel = viewModel
        self.content = AnyView(
            _SearchView(viewModel: viewModel)
        )
    }
    
    func show(atTopLeft position: CGPoint?, inferredFrom anchor: NSRect?) {
        close()
        
        let host = DraggableHostingView(rootView: content)
        host.frame = CGRect(origin: .zero, size: host.intrinsicContentSize)
        
        let size = host.intrinsicContentSize
        
        var origin: CGPoint!
        if let p = position {
            origin = CGPoint(
                x: p.x - size.width,
                y: p.y - size.height
            )
        } else if let a = anchor {
            origin = CGPoint(
                x: a.midX - size.width / 2,
                y: a.minY - size.height - 5 // 5pt gap below status item
            )
        } else {
            fatalError("Must provide position or anchor.")
        }
        
        _panel = FocusablePanel(
            contentRect: CGRect(origin: origin, size: size),
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
        
        //        _panel.orderFront(nil)
        _panel.makeKeyAndOrderFront(nil)
        // TODO: release nspanel
        
        outsideClickMonitor.start()
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
