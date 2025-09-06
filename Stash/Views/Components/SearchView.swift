//
//  CustomMenu.swift
//  Stash
//
//  Created by Assistant on 2025/7/15.
//

import SwiftUI
import AppKit
import CombineExt

struct SearchView: View {
    @StateObject var viewModel: SearchViewModel
    @State private var focused = true
    @State private var height: CGFloat = 0
    @State private var visibleRange: Range<Int> = 0..<0
    
    let onTap: (any Entry) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            searchField()
            if viewModel.items.count > 0 {
                list()
            }
        }
        .frame(width: 500)
        .onAppear {
            focused = true
        }
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
        .onReceive(viewModel.bookmark) { value in
            onTap(value)
        }
    }
    
    @ViewBuilder
    private func list() -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(Array(viewModel.items).enumerated()), id: \.element.id) { index, item in
                        // TODO: need a dummy search view item to deal with go back.
                        _SearchItemView(
                            item: item,
                            highlight: self.viewModel.index == nil ? false : (self.viewModel.index! == index),
                            onTap: { viewModel.select($0) },
                            searchText: $viewModel.query
                        )
                        .id(index)
                        .overlay(
                            GeometryReader { geo in
                                Color.clear
                                    .preference(
                                        key: VisibleRangeSignal.self,
                                        value: [index: geo.frame(in: .named("scrollView")).minY...geo.frame(in: .named("scrollView")).maxY]
                                    )
                            }
                        )
                    }
                }
                .overlay(
                    GeometryReader { proxy in
                        Color.clear.preference(key: HeightSignal.self, value: proxy.size.height)
                    }
                )
            }
            .onPreferenceChange(HeightSignal.self) { height = $0 }
            .frame(height: min(height, 300))   // 👈 set exact viewport height
            .padding(.bottom, 12)
            .coordinateSpace(name: "scrollView")
            .onPreferenceChange(VisibleRangeSignal.self) { values in
                visibleRange = VisibleRangeSignal.computeVisibleRange(from: values, containerHeight: min(height, 300))
            }
            .onReceive(viewModel.$index.compactMap({ $0 }).withLatestFrom(viewModel.$keyboardAction.compactMap({ $0 }), resultSelector: {($0, $1)})) { event in
                guard !visibleRange.contains(event.0) else { return }
                DispatchQueue.main.asyncAfter(deadline: (DispatchTime.now() + 0.1)) {
                    switch event.1 {
                    case .up:
                        withAnimation(.easeInOut(duration: 0.15)) { proxy.scrollTo(event.0, anchor: .top) }
                    case .down:
                        withAnimation(.easeInOut(duration: 0.15)) { proxy.scrollTo(event.0, anchor: .bottom) }
                    case .enter:
                        return
                    }
                }
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
            SearchField(text: $viewModel.query, keyboardAction: $viewModel.keyboardAction, focused: $focused, placeholder: Binding(
                get: {
                    switch viewModel.depth {
                    case .root:
                        return "Search by Title or Address"
                    case .group(let name):
                        return "Search in Group \"\(name)\""
                    }
                },
                set: { _ in }
            ))
                .font(NSFont.systemFont(ofSize: 18, weight: .light))
            if !viewModel.query.isEmpty {
                Button(action: {
                    viewModel.query = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .buttonStyle(BorderlessButtonStyle()) // Important for macOS!
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
    }
}


class FocusablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    
    override func cancelOperation(_ sender: Any?) {
        self.close() // Or orderOut(nil) if you just want to hide
    }
}
