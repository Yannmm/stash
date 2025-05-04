//
//  AddressInputField.swift
//  Stash
//
//  Created by Rayman on 2025/2/27.
//

import SwiftUI

// https://dribbble.com/shots/20559566-Link-input-with-preview

struct AddressInputField: View {
    @FocusState private var focused: Bool
    @StateObject var viewModel: CraftViewModel
    
    var body: some View {
        HStack(spacing: 6) {
            if viewModel.loading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .red))
                    .scaleEffect(0.5, anchor: .center)
                    .frame(width: 16, height: 16)
            } else if let _ = viewModel.icon {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color.primary)
                    .frame(width: 16, height: 16)
            } else {
                Image(systemName: "link.circle.fill")
                    .resizable()
                    .frame(width: 16, height: 16)
            }
            Divider()
            TextField("Drop or Enter Path to Create New Bookmark.", text: $viewModel.path ?? "")
            .textFieldStyle(.plain)
            .focused($focused)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(focused ? Color.primary : Color(nsColor: .separatorColor),
                        lineWidth: 1)
        )
        .focusable()
        .onHover { isHovered in
            if isHovered {
                NSCursor.iBeam.push()
            } else {
                NSCursor.pop()
            }
        }
        .onAppear {
            focused = true
        }
        .onChange(of: viewModel.path ?? "", { _, value in
            viewModel.parsable = !value.isEmpty
            
        })
        .onSubmit {
            Task {
                do {
                    try await viewModel.parse()
                } catch {
                    viewModel.error = error
                }
            }
        }
    }
}
