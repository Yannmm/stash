//
//  OutsideClicker.swift
//  Stash
//
//  Created by Rayman on 2025/7/30.
//

import AppKit

class OutsideClickMonitor {
    
    let areaProvider: () -> CGRect
    
    let onClose: () -> Void
    
    init(areaProvider: @escaping () -> CGRect, onClose: @escaping () -> Void) {
        self.areaProvider = areaProvider
        self.onClose = onClose
    }
    
    private var monitor: Any?
    
    func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self else {
                // If self is nil, the monitor should be removed
                return
            }
            
            let frame = self.areaProvider()
            // Convert the event location to screen coordinates
            let location = NSEvent.mouseLocation
            
            // If the click is outside the panel, close it
            if !frame.contains(location) {
                self.onClose()
                self.stop()
            }
        }
    }
    
    func stop() {
        if let m = monitor {
            NSEvent.removeMonitor(m)
            monitor = nil
        }
    }
    
    deinit {
        stop()
    }
    
}
