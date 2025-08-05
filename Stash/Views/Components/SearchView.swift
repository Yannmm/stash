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
    @State private var focused = true
    @State private var index: Int?
    
    var body: some View {
        VStack(spacing: 0) {
            searchField()
            VStack(spacing: 0) {
                ForEach(Array(Array(viewModel.items).enumerated()), id: \.element.id) { index, item in
                    _SearchItemView(
                        item: item,
                        highlight: self.index == index,
                        searchText: $viewModel.searchText
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
        .onReceive(viewModel.$keyboardAction) { newValue in // $viewModel.keyboardAction 🙅
                        print("Value changed to: \(newValue)")
                        // perform some side effect here
                    }
        .onReceive(viewModel.$keyboardAction) { value in
            print("123123")
            guard let direction = value else { return }
            switch direction {
            case .down: // ↓ Down arrow
                index = index == nil ? 0 : (index! + 1) % viewModel.items.count
                print("xxxxxxxxx -> \(index)")
            case .up: // ↑ Up arrow
                index = index == nil ? 0 : (index! - 1 + viewModel.items.count) % viewModel.items.count
            case .enter:
                guard let idx = index else { return }
                // TODO: implement ontap
                //                onTap(viewModel.hashtags[idx])
                index = nil
            }
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
