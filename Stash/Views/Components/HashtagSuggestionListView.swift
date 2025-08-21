//
//  SuggestionListView.swift
//  Stash
//
//  Created by Yan Meng on 2025/6/27.
//

import SwiftUI

struct HashtagSuggestionListView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var index: Int?
    let onTap: (String) -> Void
    @EnvironmentObject var viewModel: HashtagViewModel
    @State private var hovering: Bool = false
    
    
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
                .listRowBackground(index == idx ? Color.theme.opacity(0.3) : Color.clear)
                .frame(maxWidth: .infinity)
                .onTapGesture {
                    hovering = false
                    onTap(viewModel.hashtags[idx])
                    index = nil
                }
//                .onHover { flag in
//                    hovering = flag
//                    if hovering {
//                        index = idx
//                    }
//                }
            }
            .listStyle(.plain)
            .padding(0)
            .frame(width: 200, height: 150)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(6)
            .onChange(of: index) { _, index in
                guard !hovering else { return }
                withAnimation(.easeInOut(duration: 0.15)) {
                    proxy.scrollTo(index, anchor: .center)
                }
            }
            .onReceive(viewModel.$keyboardAction, perform: { value in
                hovering = false
                guard let direction = value else { return }
                switch direction {
                case .down: // ↓ Down arrow
                    index = index == nil ? 0 : (index! + 1) % viewModel.hashtags.count
                case .up: // ↑ Up arrow
                    index = index == nil ? 0 : (index! - 1 + viewModel.hashtags.count) % viewModel.hashtags.count
                case .enter:
                    guard let idx = index else { return }
                    onTap(viewModel.hashtags[idx])
                    index = nil
                }
            })
        }
    }
}
