//
//  fff.swift
//  Stash
//
//  Created by Rayman on 2025/7/29.
//

import AppKit
import SwiftUI

class FloatingPanel {
    private var _panel: FocusablePanel!
    
    private lazy var outsideClickMonitor: OutsideClickMonitor = {
        OutsideClickMonitor { [weak self] in
            self?._panel?.frame ?? .zero
        } onClose: { [weak self] in
            self?.close()
        }
    }()
    
    func show(content: NSView, atTopLeft position: CGPoint?, inferredFrom anchor: NSRect?) {
        close()
        
        let size = content.intrinsicContentSize
        
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
        
        _panel.contentView = content
        
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
