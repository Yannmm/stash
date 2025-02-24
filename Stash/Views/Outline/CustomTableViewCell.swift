//
//  CustomTableViewCell.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/18.
//

import AppKit
import SwiftUI

class CustomTableViewCell: NSTableCellView {
    
    var entry: (any Entry)? {
        didSet {
            guard let e = entry else { return }
            hostingView.rootView = CellContent(entry: e)
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: CGRectZero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var hostingView: NSHostingView<CellContent>!
    
    private func setup() {
        let content = NSHostingView(rootView: CellContent(entry: nil))
        self.hostingView = content
        content.sizingOptions = .minSize
        self.addSubview(content)
        
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: self.topAnchor),
            content.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            content.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }
    
    private var trackingArea: NSTrackingArea?
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        NSColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.00).set()
        
        // mouse hover
        if highlight {
            let path = NSBezierPath(rect: bounds)
            path.fill()
        }
        
        // draw divider
//        let rect = NSRect(x: 0, y: bounds.height - 2, width: bounds.width, height: bounds.height)
//        let path = NSBezierPath(rect: rect)
//        path.fill()
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
