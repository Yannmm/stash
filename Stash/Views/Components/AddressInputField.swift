//
//  AddressInputField.swift
//  Stash
//
//  Created by Rayman on 2025/2/27.
//

import SwiftUI

// https://dribbble.com/shots/20559566-Link-input-with-preview

struct AddressInputField: View {
    let placeholder: String
    @State var text: String
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
                    .foregroundColor(Color.theme)
                    .frame(width: 16, height: 16)
            } else {
                Image(systemName: "link")
                    .resizable()
                    .frame(width: 16, height: 16)
            }
            Divider()
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .focused($focused)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(focused ? Color.theme : Color(nsColor: .separatorColor),
                        lineWidth: focused ? 2 : 0.5)
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
        .onSubmit {
            Task {
                do {
                    try await viewModel.parse(text)
                } catch {
                    print(error)
                }
            }
        }
    }
}

#Preview {
//    AddressInputField()
}
