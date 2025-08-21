//
//  CustomMenu.swift
//  Stash
//
//  Created by Assistant on 2025/7/15.
//

import SwiftUI
import AppKit

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
        .onReceive(viewModel.selectedEntry) { value in
            onTap(value)
        }
    }
    
    @ViewBuilder
    private func list() -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(Array(viewModel.items).enumerated()), id: \.element.id) { index, item in
                        _SearchItemView(
                            item: item,
                            highlight: self.viewModel.index == nil ? false : (self.viewModel.index! == index),
                            onTap: { viewModel.setSelectedItem($0) },
                            searchText: $viewModel.query
                        )
                        .id(index)
                        .overlay(
                            GeometryReader { geo in
                                Color.clear
                                    .preference(
                                        key: VisibleRangeKey.self,
                                        value: [index: geo.frame(in: .named("scroll")).minY...geo.frame(in: .named("scroll")).maxY]
                                    )
                            }
                        )
                    }
                }
                .overlay(
                    GeometryReader { proxy in
                        Color.clear.preference(key: HeightKey.self, value: proxy.size.height)
                    }
                )
            }
            .onPreferenceChange(HeightKey.self) { height = $0 }
            .frame(height: min(height, 300))   // 👈 set exact viewport height
            .padding(.bottom, 12)
            .onPreferenceChange(VisibleRangeKey.self) { values in
                visibleRange = computeVisibleRange(from: values, containerHeight: min(height, 300))
            }
            .onReceive(viewModel.$index.compactMap({ $0 }).withLatestFrom(viewModel.$keyboardAction.compactMap({ $0 }))) { event in
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
            SearchField(text: $viewModel.query, keyboardAction: $viewModel.keyboardAction, focused: $focused)
                .font(NSFont.systemFont(ofSize: 20, weight: .light))
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

private extension SearchView {
    struct HeightKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
    }
    
    struct VisibleRangeKey: PreferenceKey {
        static var defaultValue: [Int: ClosedRange<CGFloat>] = [:]
        static func reduce(value: inout [Int: ClosedRange<CGFloat>], nextValue: () -> [Int: ClosedRange<CGFloat>]) {
            value.merge(nextValue(), uniquingKeysWith: { $1 })
        }
    }
}

/// Compute which indexes are fully visible inside the container height
func computeVisibleRange(from values: [Int: ClosedRange<CGFloat>], containerHeight: CGFloat) -> Range<Int> {
    let visible = values
        .filter { $0.value.lowerBound >= 0 && $0.value.upperBound <= containerHeight }
        .map { $0.key }
        .sorted()
    
    if let first = visible.first, let last = visible.last {
        return first..<last+1
    } else {
        return 0..<0
    }
}


class FocusablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    
    override func cancelOperation(_ sender: Any?) {
        self.close() // Or orderOut(nil) if you just want to hide
    }
}
