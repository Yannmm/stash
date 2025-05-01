//
//  CustomTableRowView.swift
//  Stash
//
//  Created by Rayman on 2025/3/6.
//

import AppKit
import SwiftUI

class RowView: NSTableRowView {
    
    var id: UUID?
    
    let ignoreMouseEvent: () -> Bool
    
    init(ignoreMouseEvent: @escaping () -> Bool) {
        self.ignoreMouseEvent = ignoreMouseEvent
        super.init(frame: NSRect.zero)
        
        NotificationCenter.default.addObserver(forName: .onClearRowView, object: nil, queue: nil) { noti in
            self.highlight = false
        }
    }
    
    var isFocused = false {
        didSet {
            setNeedsDisplay(bounds)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Hover
    private var trackingArea: NSTrackingArea?
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard !isSelected else { return }
        guard !isFocused else { return }
        guard !NSEvent.modifierFlags.containsOnly(.command) else { return }
        
        // mouse hover
        if highlight {
            NSColor.gridColor.set()
            let path = NSBezierPath(rect: bounds)
            path.fill()
        }
    }
    
    private var highlight = false {
        didSet {
            setNeedsDisplay(bounds)
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        guard !ignoreMouseEvent() else { return }
        
        highlight = true
        
        if !isSelected {
            NotificationCenter.default.post(name: .onHoverRowView, object: (id, true))
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        guard !ignoreMouseEvent() else { return }
        
        highlight = false
        
        if !isSelected {
//            NotificationCenter.default.post(name: .onHoverRowView, object: (id, false) as (UUID?, Bool))
            NotificationCenter.default.post(name: .onClearRowView, object: nil)
        }
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        if (trackingArea != nil) {
            self.removeTrackingArea(trackingArea!)
        }
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways]
        let trackingArea = NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
    
    deinit {
        if (trackingArea != nil) {
            removeTrackingArea(trackingArea!)
        }
    }
}
