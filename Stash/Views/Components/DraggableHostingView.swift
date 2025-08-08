//
//  DraggableHostingView.swift
//  Stash
//
//  Created by Rayman on 2025/8/6.
//

import SwiftUI

class DraggableHostingView<Content: View>: NSHostingView<Content> {
    private var initialLocation: NSPoint = .zero
    private var initialWindowLocation: NSPoint = .zero
    private var isDragging = false

    override func mouseDown(with event: NSEvent) {
        guard let window = self.window else { return }
        initialLocation = NSEvent.mouseLocation
        initialWindowLocation = window.frame.origin
        isDragging = false
        
        // Call super to allow SwiftUI gestures to work
        super.mouseDown(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let window = self.window else { return }
        let currentLocation = NSEvent.mouseLocation
        let deltaX = currentLocation.x - initialLocation.x
        let deltaY = currentLocation.y - initialLocation.y
        
        // Only start dragging if there's significant movement (to distinguish from clicks)
        let distance = sqrt(deltaX * deltaX + deltaY * deltaY)
        if distance > 3.0 { // 3 pixel threshold
            isDragging = true
        }
        
        if isDragging {
            let newOrigin = NSPoint(
                x: initialWindowLocation.x + deltaX,
                y: initialWindowLocation.y + deltaY
            )
            window.setFrameOrigin(newOrigin)
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        // If we weren't dragging, let SwiftUI handle the tap
        if !isDragging {
            super.mouseUp(with: event)
        }
        isDragging = false
    }
}
