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
    
    init() {
        super.init(frame: NSRect.zero)
    }
    
    var isFocused = false {
        didSet {
            setNeedsDisplay(bounds)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
