//
//  CustomTableRowView.swift
//  Stash
//
//  Created by Rayman on 2025/3/6.
//

import AppKit
import SwiftUI

class RowView: NSTableRowView {
    
    override init(frame frameRect: NSRect) {
        super.init(frame: NSRect.zero)
    }
    
    var isFocused = false {
        didSet {
            setNeedsDisplay(bounds)
        }
    }
    
    var id: UUID?
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Selection
    override func drawSelection(in dirtyRect: NSRect) {
        if self.selectionHighlightStyle != .none {
            //            let selectionRect = NSInsetRect(self.bounds, 2.5, 2.5)
            let selectionRect = self.bounds
            NSColor(Color.accentColor).setFill()
            let selectionPath = NSBezierPath.init(roundedRect: selectionRect, xRadius: 0, yRadius: 0)
            selectionPath.fill()
        }
    }
    
    // Hover
    private var trackingArea: NSTrackingArea?
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard !isSelected else { return }
        guard !isFocused else { return }
        
        NSColor.gridColor.set()
        
        // mouse hover
        if highlight {
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
        if !highlight {
            highlight = true
        }
        
        if !isSelected {
            NotificationCenter.default.post(name: .onHoverRowView, object: (id, true))
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        if highlight {
            highlight = false
        }
        
        if !isSelected {
            NotificationCenter.default.post(name: .onHoverRowView, object: (id, false))
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
