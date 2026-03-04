//
//  HashtagField.swift
//  Stash
//
//  Created by Rayman on 2026/2/24.
//

import SwiftUI
import Combine
import OrderedCollections

struct HashtagField: View {
    @StateObject private var viewModel: HashtagInputViewModel
    @Binding var hashtags: OrderedSet<String>?
    let disabled: Bool
    var onSubmit: (() -> Void)?
    
    @FocusState private var focused: Bool
    
    init(
         existentials: AnyPublisher<OrderedSet<String>, Never>,
         hashtags: Binding<OrderedSet<String>?>,
         disabled: Bool,
         onSubmit: (() -> Void)? = nil
     ) {
         _viewModel = StateObject(
             wrappedValue: HashtagInputViewModel(existentials: existentials)
         )
         _hashtags = hashtags
         self.disabled = disabled
         self.onSubmit = onSubmit
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
                viewModel: viewModel,
                focused: focused,
                hashtags: $hashtags,
                onSubmit: onSubmit
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
