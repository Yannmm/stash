//
//  DragPosition.swift
//  Stash
//
//  Created by Rayman on 2026/2/9.
//

import SwiftUI

enum DragPosition {
    case `in`
    case before
    case after
}

struct Dropper<T: Identifiable>: DropDelegate {
    let id: T.ID
    @Binding var dragging: T?
    @Binding var dragPosition: DragPosition?
    let rowHeight: CGFloat
    let expanded: Bool
    let onDrop: (T.ID, T.ID, DragPosition) -> Void
    let cascade: (T.ID, T.ID) -> Bool
    let propose: (DragPosition) -> DropProposal
    
    // Only before/after zones - middle zone is rejected
    private var threshold: CGFloat { rowHeight / 3 }
    
    func validateDrop(info: DropInfo) -> Bool {
        guard let drag = dragging else { return false }
        return drag.id != id
    }
    
    func performDrop(info: DropInfo) -> Bool {
        guard let drag = dragging,
              drag.id != id,
              let position = dragPosition else {
            reset()
            return false
        }
        
        onDrop(id, drag.id, position)
        self.dragging = nil
        reset()
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard dragging?.id != id else { return }
        _updatePosition(info)
    }
    
    func dropExited(info: DropInfo) {
        reset()
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        guard dragging?.id != id else {
            return DropProposal(operation: .forbidden)
        }
        
        _updatePosition(info)
        
        if let position = dragPosition {
            return propose(position)
        } else {
            return nil
        }
    }
    
    private func reset() {
        dragPosition = nil
    }
    
    private func _updatePosition(_ info: DropInfo) {
        guard let drag = dragging else { return }
        guard !cascade(id, drag.id) else { return }
        
        let location = info.location
        
        if location.y < threshold {
            dragPosition = .before
        } else if location.y > (rowHeight - threshold) {
            if expanded {
                dragPosition = .in
            } else {
                dragPosition = .after
            }
        } else {
            dragPosition = .in
        }
    }
}
