//
//  CustomMenu.swift
//  Stash
//
//  Created by Assistant on 2025/7/15.
//

import SwiftUI
import AppKit

1. tap esc to dismiss
2. remember last drag frame.

// Menu content
struct _SearchView: View {
    @StateObject var viewModel: SearchViewModel
    @State private var focused = true
    
    var body: some View {
        VStack(spacing: 0) {
            searchField()
            VStack(spacing: 0) {
                ForEach(Array(Array(viewModel.items).enumerated()), id: \.element.id) { index, item in
                    _SearchItemView(
                        item: item,
                        highlight: self.viewModel.index == nil ? false : (self.viewModel.index! == index),
                        onTap: { viewModel.setSelectedItem($0) },
                        searchText: $viewModel.searchText,
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
        .onAppear(perform: {
            focused = true
        })
        .onReceive(viewModel.selectedItem) { value in
            print("狗 -> \(value)")
        }
    }
    
    @ViewBuilder
    private func searchField() -> some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkle.magnifyingglass")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 18, height: 18)
                .foregroundStyle(Color.theme)
            SearchField(text: $viewModel.searchText, keyboardAction: $viewModel.keyboardAction, focused: $focused) {
                
            }
            .font(NSFont.systemFont(ofSize: 20, weight: .light))
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
