//
//  AddressInputField.swift
//  Stash
//
//  Created by Rayman on 2025/2/27.
//

import SwiftUI

// https://dribbble.com/shots/20559566-Link-input-with-preview

struct AddressInputField: View {
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var focused: Bool
    @Binding var loading: Bool
    @Binding var icon: Icon?
    @Binding var path: String?
    
    var body: some View {
        HStack(spacing: 6) {
            if loading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .red))
                    .scaleEffect(0.5, anchor: .center)
                    .frame(width: 16, height: 16)
            } else if let _ = icon {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color.theme)
                    .frame(width: 16, height: 16)
            } else {
                Image(systemName: "link.circle")
                    .resizable()
                    .foregroundColor(.secondary)
                    .frame(width: 16, height: 16)
            }
            Divider()
            TextField("Drop or Enter Path to Create Bookmark.", text: $path ?? "")
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
    }
}
