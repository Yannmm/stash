//
//  AppDelegate+Search.swift
//  Stash
//
//  Created by Yan Meng on 2025/7/17.
//

import AppKit
import SwiftUI

extension AppDelegate {
    @objc func search() {
        searchPanel = FloatingPanel(at: statusItemButtonFrame, viewModel: searchViewModel)
        searchPanel?.show()
    }
    
    private var statusItemButtonFrame: NSRect {
        if let button = statusItem?.button,
           let frame = button.window?.convertToScreen(button.convert(button.bounds, to: nil)) {
            return frame
        }
        return .zero
    }
}
