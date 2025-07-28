//
//  CustomMenu.swift
//  Stash
//
//  Created by Assistant on 2025/7/15.
//

import SwiftUI
import AppKit

class Menu {
    let anchorRect: NSRect
    let content: AnyView
    let viewModel: SearchViewModel
    init(at anchorRect: NSRect, viewModel: SearchViewModel) {
        self.anchorRect = anchorRect
        self.viewModel = viewModel
        self.content = AnyView(_SearchView(viewModel: viewModel))
    }
    
    private var _panel: FocusablePanel!
    
    func show() {
        close()
        
        let hosting = NSHostingController(rootView: content)
        hosting.view.frame = CGRect(origin: .zero, size: hosting.view.intrinsicContentSize)
        
        _panel = FocusablePanel(
            contentRect: hosting.view.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        //        _panel.level = .statusBar
        _panel.isOpaque = true
        _panel.backgroundColor = NSColor.clear
        _panel.hasShadow = true
        _panel.worksWhenModal = true
        _panel.becomesKeyOnlyIfNeeded = false
        _panel.acceptsMouseMovedEvents = true
        _panel.isFloatingPanel = false
        _panel.hidesOnDeactivate = false
        _panel.isReleasedWhenClosed = false
        _panel.level = .normal
        
        _panel.contentViewController = hosting
        
        let panelSize = hosting.view.intrinsicContentSize // your panel's size
        
        // Position the panel below the status item
        let point = CGPoint(
            x: anchorRect.midX - panelSize.width / 2,
            y: anchorRect.minY - panelSize.height - 5 // 5pt gap below status item
        )
        
        _panel.setFrameOrigin(point)
        //        _panel.orderFront(nil)
        _panel.makeKeyAndOrderFront(nil)
        // TODO: release nspanel
    }
    
    func close() {
        _panel?.close()
        _panel = nil
    }
}

// Menu content
struct _SearchView: View {
    @StateObject var viewModel: SearchViewModel
    @State private var hovered: UUID?
    @State private var hovering = false
    
    @FocusState private var focused: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            searchField()
            ForEach(Array(Array(viewModel.items).enumerated()), id: \.element.id) { index, item in
                _SearchItemView(
                    item: item
                )
            }
            
        }
        .frame(width: 500)
        .onAppear {
            focused = true
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(
                    color: .black.opacity(0.15),
                    radius: 10,
                    x: 0,
                    y: 4
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(NSColor.separatorColor).opacity(0.3), lineWidth: 0.5)
        )
    }
    
    @ViewBuilder
    private func searchField() -> some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkle.magnifyingglass")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .foregroundStyle(Color.theme)
            TextField("Search", text: $viewModel.searchText)
                .controlSize(.extraLarge)
                .font(.system(size: 20, weight: .regular))
                .textFieldStyle(PlainTextFieldStyle())
                .focused($focused)
            if !viewModel.searchText.isEmpty {
                Button(action: {
                    viewModel.searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .buttonStyle(BorderlessButtonStyle()) // Important for macOS!
            }
        }
        .padding(.horizontal, 8)
    }
}


class FocusablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
