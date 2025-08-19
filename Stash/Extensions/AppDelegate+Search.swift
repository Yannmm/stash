//
//  AppDelegate+Search.swift
//  Stash
//
//  Created by Yan Meng on 2025/7/17.
//

import AppKit
import SwiftUI

extension AppDelegate {
    @MainActor
    @objc func search() {
        searchPanel = FloatingPanel()
        searchPanel?.show(
            content: DraggableHostingView(rootView:
                                            SearchView(viewModel: self.searchViewModel, onTap: { [weak self] in
                                                self?.act(upon: $0)
                                                self?.searchPanel?.close()
                                            })
                                         ),
            atTopLeft: searchPanelPosition,
            inferredFrom: statusItemButtonFrame
        )
    }
    
    private var statusItemButtonFrame: NSRect {
        if let button = statusItem?.button,
           let frame = button.window?.convertToScreen(button.convert(button.bounds, to: nil)) {
            return frame
        }
        return .zero
    }
}
