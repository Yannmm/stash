//
//  CustomTableRowView.swift
//  Stash
//
//  Created by Rayman on 2025/3/6.
//

import AppKit

class CustomTableRowView: NSTableRowView {
    override init(frame frameRect: NSRect) {
        super.init(frame: CGRectZero)
        //        setup()
    }
    
    var isFocused = false {
        didSet {
            print("🐶 --> \(isFocused)")
            setNeedsDisplay(bounds)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Selection
    override func drawSelection(in dirtyRect: NSRect) {
        if self.selectionHighlightStyle != .none {
            let selectionRect = NSInsetRect(self.bounds, 2.5, 2.5)
            NSColor(calibratedWhite: 0.65, alpha: 1).setStroke()
            NSColor(calibratedWhite: 0.82, alpha: 1).setFill()
            let selectionPath = NSBezierPath.init(roundedRect: selectionRect, xRadius: 6, yRadius: 6)
            selectionPath.fill()
            selectionPath.stroke()
        }
    }
    
    // Hover
    private var trackingArea: NSTrackingArea?
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard !isSelected else { return }
        guard !isFocused else { return }
        
//        NSColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.00).set()
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
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        if highlight {
            highlight = false
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
