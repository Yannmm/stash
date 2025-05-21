//
//  CellView.swift
//  Stash
//
//  Created by Rayman on 2025/5/21.
//

import AppKit
import SwiftUI

class CellView: NSTableCellView {
    
    var entry: (any Entry)? {
        didSet {
            hostingView.rootView = CellContent(viewModel: CellViewModel(entry: entry))
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
        let content = NSHostingView(rootView: CellContent(viewModel: CellViewModel()))
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
}
