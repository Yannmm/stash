//
//  SuggestionListView.swift
//  Stash
//
//  Created by Yan Meng on 2025/6/27.
//

import SwiftUI

struct HashtagSuggestionListView: View {
    @EnvironmentObject var viewModel: HashtagViewModel
    @Environment(\.colorScheme) var colorScheme
    let onTap: (String) -> Void
    @State private var visibleRange: Range<Int> = 0..<0
    
    var body: some View {
        ScrollViewReader { proxy in
            List(Array(viewModel.hashtags.enumerated()), id: \.offset) { idx, fruit in
                HStack {
                    Text(fruit)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .font(.system(size: 18, weight: .thin))
                        .padding(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10))
                    Spacer() // Fill remaining space
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowSeparator(.hidden)
                .listRowBackground(viewModel.suggestionIndex == idx ? Color.theme.opacity(0.3) : Color.clear)
                .frame(maxWidth: .infinity)
                .id(idx)
                .overlay(
                    GeometryReader { geo in
                        Color.clear
                            .preference(
                                key: VisibleRangeSignal.self,
                                value: [idx: geo.frame(in: .named("scroll")).minY...geo.frame(in: .named("scroll")).maxY]
                            )
                    }
                )
                .onTapGesture {
                    onTap(viewModel.hashtags[idx])
//                    index = nil
                }
            }
            .listStyle(.plain)
            .padding(0)
            .frame(width: Constant.width, height: Constant.height)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(6)
            .onPreferenceChange(VisibleRangeSignal.self) { values in
                visibleRange = VisibleRangeSignal.computeVisibleRange(from: values, containerHeight: Constant.height)
            }
            // TODO: set $keyboardAction
            .onReceive(viewModel.$suggestionIndex.compactMap({ $0 }).withLatestFrom(viewModel.$keyboardAction.compactMap({ $0 }))) { event in
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
}

extension HashtagSuggestionListView {
    enum Constant {
        static let height = 150.0
        static let width = 200.0
    }
}
