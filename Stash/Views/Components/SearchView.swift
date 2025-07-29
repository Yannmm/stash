//
//  CustomMenu.swift
//  Stash
//
//  Created by Assistant on 2025/7/15.
//

import SwiftUI
import AppKit

// Menu content
struct _SearchView: View {
    @StateObject var viewModel: SearchViewModel
    @State private var hovered: UUID?
    @State private var hovering = false
    
    @FocusState private var focused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            searchField()
            VStack(spacing: 0) {
                ForEach(Array(Array(viewModel.items).enumerated()), id: \.element.id) { index, item in
                    _SearchItemView(
                        item: item
                    )
                }
            }
            .padding(.top, viewModel.items.count > 0 ? 12 : 0)
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
