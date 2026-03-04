//
//  SuggestionListView.swift
//  Stash
//
//  Created by Yan Meng on 2025/6/27.
//

import SwiftUI

struct HashtagSuggestionListView: View {
    @EnvironmentObject var viewModel: HashtagInputViewModel
    @Environment(\.colorScheme) var colorScheme
    let onTap: (String) -> Void
    @State private var visibleRange: Range<Int> = 0..<0
    @State private var hoveredIndex: Int?
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 1) {
                    ForEach(Array(viewModel.hashtags.enumerated()), id: \.offset) { idx, hashtag in
                        HStack(spacing: 0) {
                            Text(hashtag)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .font(.system(size: 13))
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(backgroundColor(for: idx))
                        )
                        .padding(.horizontal, 5)
                        .id(idx)
                        .contentShape(Rectangle())
                        .overlay(
                            GeometryReader { geo in
                                Color.clear
                                    .preference(
                                        key: VisibleRangeSignal.self,
                                        value: [idx: geo.frame(in: .named("scroll")).minY...geo.frame(in: .named("scroll")).maxY]
                                    )
                            }
                        )
                        .onHover { isHovered in
                            hoveredIndex = isHovered ? idx : nil
                        }
                        .onTapGesture {
                            viewModel.select(hashtag)
                        }
                    }
                }
                .padding(.vertical, 5)
            }
            .coordinateSpace(name: "scroll")
            .frame(width: Constant.width, height: Constant.height)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
            )
            .onPreferenceChange(VisibleRangeSignal.self) { values in
                visibleRange = VisibleRangeSignal.computeVisibleRange(from: values, containerHeight: Constant.height)
            }
            .onReceive(viewModel.$suggestionIndex.compactMap({ $0 }).withLatestFrom(viewModel.$keyboardAction.compactMap({ $0 }), resultSelector: {($0, $1)})) { event in
                guard !visibleRange.contains(event.0) else { return }
                DispatchQueue.main.asyncAfter(deadline: (DispatchTime.now() + 0.1)) {
                    switch event.1! {
                    case KeyboardAction.up:
                        withAnimation(.easeInOut(duration: 0.15)) { proxy.scrollTo(event.0, anchor: .top) }
                    case KeyboardAction.down:
                        withAnimation(.easeInOut(duration: 0.15)) { proxy.scrollTo(event.0, anchor: .bottom) }
                    case KeyboardAction.enter:
                        return
                    }
                }
            }
            .onReceive(viewModel.selected) { value in
                onTap(value)
            }
        }
    }
    
    private func backgroundColor(for index: Int) -> Color {
        if viewModel.suggestionIndex == index {
            return Color.accentColor.opacity(0.3)
        } else if hoveredIndex == index {
            return Color.primary.opacity(0.08)
        }
        return Color.clear
    }
}

extension HashtagSuggestionListView {
    enum Constant {
        static let height = 150.0
        static let width = 200.0
    }
}
