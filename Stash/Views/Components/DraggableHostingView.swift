//
//  DraggableHostingView.swift
//  Stash
//
//  Created by Rayman on 2025/8/6.
//

import SwiftUI

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
