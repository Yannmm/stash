//
//  RightClickMonitorView.swift
//  Stash
//
//  Created by Rayman on 2026/3/17.
//

import AppKit
import SwiftUI

struct RightClickMonitorView: NSViewRepresentable {
    let onRightClick: () -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onRightClick: onRightClick)
    }
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        context.coordinator.attach(view)
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.attach(nsView)
    }
    
    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.detach()
    }
    
    final class Coordinator {
        private let onRightClick: () -> Void
        private weak var view: NSView?
        private var monitor: Any?
        
        init(onRightClick: @escaping () -> Void) {
            self.onRightClick = onRightClick
        }
        
        deinit {
            detach()
        }
        
        func attach(_ view: NSView) {
            self.view = view
            guard monitor == nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { [weak self] event in
                guard let self, let view = self.view, let window = view.window else {
                    return event
                }
                let location = view.convert(event.locationInWindow, from: nil)
                guard view.bounds.contains(location), window == event.window else {
                    return event
                }
                self.onRightClick()
                return event
            }
        }
        
        func detach() {
            if let monitor {
                NSEvent.removeMonitor(monitor)
                self.monitor = nil
            }
        }
    }
}
