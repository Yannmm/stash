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
        self.content = AnyView(
            _SearchView(viewModel: viewModel)
        )
    }
    
    private var _panel: FocusablePanel!
    
    func show() {
        close()
        
        let kk1 = NSHostingController(rootView: content)
        
        let kk = DraggableHostingView(rootView: content)
        kk.frame = CGRect(origin: .zero, size: kk1.view.intrinsicContentSize)
        let hosting = NSViewController()
        hosting.view = kk
        
        _panel = FocusablePanel(
            contentRect: hosting.view.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        

//        _panel.isOpaque = true
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


struct DragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = DraggableView()
        view.frame = .zero
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

class DraggableView: NSView {
    private var initialLocation: NSPoint = .zero

    override func mouseDown(with event: NSEvent) {
        guard let window = self.window else { return }
        initialLocation = NSEvent.mouseLocation
    }

    override func mouseDragged(with event: NSEvent) {
        guard let window = self.window else { return }
        let currentLocation = NSEvent.mouseLocation
        let deltaX = currentLocation.x - initialLocation.x
        let deltaY = currentLocation.y - initialLocation.y

        var frame = window.frame
        frame.origin.x += deltaX
        frame.origin.y += deltaY
        window.setFrame(frame, display: true)

        initialLocation = currentLocation
    }
}


class DraggableHostingView<Content: View>: NSHostingView<Content> {
    private var initialLocation: NSPoint = .zero

    override func mouseDown(with event: NSEvent) {
        guard let window = self.window else { return }
        initialLocation = NSEvent.mouseLocation
    }

    override func mouseDragged(with event: NSEvent) {
        guard let window = self.window else { return }
        let currentLocation = NSEvent.mouseLocation
        let deltaX = currentLocation.x - initialLocation.x
        let deltaY = currentLocation.y - initialLocation.y

        var frame = window.frame
        frame.origin.x += deltaX
        frame.origin.y += deltaY
        window.setFrame(frame, display: true)

        initialLocation = currentLocation
    }
}
