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
    @Binding var drag: T?
    @Binding var dragPosition: DragPosition?
    let rowHeight: CGFloat
    let expanded: Bool
    let onDrop: (T.ID, T.ID, DragPosition) -> Void
    let cascade: (T.ID, T.ID) -> Bool
    let propose: (DragPosition?) -> DropProposal?
    
    // Only before/after zones - middle zone is rejected
    private var threshold: CGFloat { rowHeight / 3 }

    func performDrop(info: DropInfo) -> Bool {
        defer { drag = nil }
        
        guard let drag = drag,
              drag.id != id,
              let position = dragPosition else {
            reset()
            return false
        }
        
        onDrop(id, drag.id, position)
        reset()
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard drag?.id != id else { return }
        _updatePosition(info)
    }
    
    func dropExited(info: DropInfo) {
        reset()
        NSCursor.arrow.set()
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        guard drag?.id != id else {
            NSCursor.operationNotAllowed.set()
            return DropProposal(operation: .forbidden)
        }
        
        _updatePosition(info)
        let proposal = propose(dragPosition)
        if proposal?.operation == .forbidden {
            NSCursor.operationNotAllowed.set()
        } else {
            NSCursor.arrow.set()
        }
        return proposal
    }
    
    private func reset() {
        dragPosition = nil
    }
    
    
    private func _updatePosition(_ info: DropInfo) {
        guard let drag = drag else { return }
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
