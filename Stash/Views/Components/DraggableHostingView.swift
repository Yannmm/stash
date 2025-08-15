//
//  DraggableHostingView.swift
//  Stash
//
//  Created by Rayman on 2025/8/6.
//

import SwiftUI

class DraggableHostingView<Content: View>: NSHostingView<Content> {
    /// User drag location
    private var pinpoint: NSPoint = .zero
    /// Window / Panel origin
    private var origin: NSPoint = .zero
    private var dragging = false
    
    override func mouseDown(with event: NSEvent) {
        guard let window = self.window else { return }
        pinpoint = NSEvent.mouseLocation
        origin = window.frame.origin
        dragging = false
        
        // Call super to allow SwiftUI gestures to work
        super.mouseDown(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let window = self.window else { return }
        let mouse = NSEvent.mouseLocation
        let deltaX = mouse.x - pinpoint.x
        let deltaY = mouse.y - pinpoint.y
        
        // Only start dragging if there's significant movement (to distinguish from clicks)
        let distance = sqrt(deltaX * deltaX + deltaY * deltaY)
        if distance > 3.0 { // 3 pixel threshold
            dragging = true
        }
        
        if dragging {
            let no = NSPoint(
                x: origin.x + deltaX,
                y: origin.y + deltaY
            )
            window.setFrameOrigin(no)
        }
        
        NotificationCenter.default.post(name: .onDragWindow, object: window)
    }
    
    override func mouseUp(with event: NSEvent) {
        // If we weren't dragging, let SwiftUI handle the tap
        if !dragging {
            super.mouseUp(with: event)
        }
        dragging = false
    }
}
