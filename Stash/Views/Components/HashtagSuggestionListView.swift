//
//  SuggestionListView.swift
//  Stash
//
//  Created by Yan Meng on 2025/6/27.
//

import SwiftUI

struct HashtagSuggestionListView: View {
    let onTap: (String) -> Void
    @EnvironmentObject var viewModel: HashtagViewModel
    
    @State private var activeIndex: Int?
    @State private var isHovering: Bool = false
    
    
    var body: some View {
        ScrollViewReader { proxy in
            List(Array(viewModel.hashtags.enumerated()), id: \.offset) { index, fruit in
                HStack {
                    Text(fruit)
                        .bold()
                        .foregroundColor(.secondary)
                        .padding(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10))
                    Spacer() // Fill remaining space
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowSeparator(.hidden)
                .listRowBackground(activeIndex == index ? Color.primary.opacity(0.3) : Color.clear)
                .frame(maxWidth: .infinity)
                .onTapGesture {
                    activeIndex = index
                    isHovering = false
                }
                .onHover { hovering in
                    isHovering = hovering
                    if hovering {
                        activeIndex = index
                    }
                }
            }
            .listStyle(.plain)
            .padding(0)
            .frame(width: 200, height: 150)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(6)
            .onChange(of: activeIndex) { index in
                withAnimation(.easeInOut(duration: 0.15)) {
                    proxy.scrollTo(index, anchor: .center)
                }
            }
            .onReceive(viewModel.keyboard, perform: { value in
                guard let direction = value else { return }
                switch direction {
                case .down: // ↓ Down arrow
                    activeIndex = activeIndex == nil ? 0 : (activeIndex! + 1) % viewModel.hashtags.count
                case .up: // ↑ Up arrow
                    // TODO: might out of range
                    activeIndex = activeIndex == nil ? 0 : (activeIndex! - 1 + viewModel.hashtags.count) % viewModel.hashtags.count
                case .enter:
                    onTap(viewModel.hashtags[activeIndex ?? 0])
                }
            })
        }
    }
}
