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
            setup(entry)
        }
    }
    
    let focusMonitor: FocusMonitor
    
    let cabinet: OkamuraCabinet
    
    init(focusMonitor: FocusMonitor, cabinet: OkamuraCabinet) {
        self.focusMonitor = focusMonitor
        self.cabinet = cabinet
        super.init(frame: CGRectZero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var hostingView: NSHostingView<AnyView>!
    
    private func setup(_: (any Entry)?) {
        hostingView?.removeFromSuperview()
        hostingView?.prepareForReuse()
        
        let content = NSHostingView(rootView: AnyView(CellContent(viewModel: CellViewModel(entry: entry))
            .environmentObject(focusMonitor)
            .environmentObject(cabinet)))
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

extension CellView {
    enum Constant {
        static let bookmarkHeight = 60.0
        static let groupHeight = 45.0
    }
}
