//
//  HashtagField.swift
//  Stash
//
//  Created by Rayman on 2026/2/24.
//

import SwiftUI
import Combine

struct HashtagField: View {
    @StateObject private var viewModel: HashtagInputViewModel
    @Binding var hashtags: Set<String>?
    let disabled: Bool
    
    @FocusState private var focused: Bool
    
    init(
         existentials: AnyPublisher<Set<String>, Never>,
         hashtags: Binding<Set<String>?>,
         disabled: Bool
     ) {
         _viewModel = StateObject(
             wrappedValue: HashtagInputViewModel(existentials: existentials)
         )
         _hashtags = hashtags
         self.disabled = disabled
     }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "tag")
                .resizable()
                .foregroundColor(.secondary)
                .frame(width: NSImage.Constant.side1, height: NSImage.Constant.side1)
            //                .foregroundStyle(Color.theme)
            Divider()
            HashtagInput(
                viewModel: viewModel ,
                focused: focused,
                hashtags: $hashtags
            )
            .font(NSFont.systemFont(ofSize: NSFont.systemFontSize))
            .focused($focused)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .cornerRadius(6)
        .background(Color(nsColor: .controlBackgroundColor))
        .osxFocusRing(focused: focused, disabled: disabled)
    }
}
