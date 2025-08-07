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

    override func mouseDown(with event: NSEvent) {
        guard let window = self.window else { return }
        initialLocation = NSEvent.mouseLocation
        initialWindowLocation = window.frame.origin
    }

    override func mouseDragged(with event: NSEvent) {
        guard let window = self.window else { return }
        let currentLocation = NSEvent.mouseLocation
        let deltaX = currentLocation.x - initialLocation.x
        let deltaY = currentLocation.y - initialLocation.y

        let newOrigin = NSPoint(
            x: initialWindowLocation.x + deltaX,
            y: initialWindowLocation.y + deltaY
        )
        window.setFrameOrigin(newOrigin)
    }
}
