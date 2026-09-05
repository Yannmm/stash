//
//  AddressInputField.swift
//  Stash
//
//  Created by Rayman on 2025/2/27.
//

import SwiftUI

struct PathField: View {
    @Binding var loading: Bool
    @Binding var icon: Icon?
    @Binding var path: String?
    @FocusState.Binding var focusedField: EntryEditor.Field?
    
    var body: some View {
        HStack(spacing: 6) {
            iconView
            Divider()
            TextField("Enter url or file path", text: $path ?? "")
                .textFieldStyle(.plain)
                .focused($focusedField, equals: .path)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .cornerRadius(6)
        .background(Color(nsColor: .controlBackgroundColor))
        .osxFocusRing(focused: focusedField == .path, disabled: false)
    }
    
    @ViewBuilder
    private var iconView: some View {
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
    }
}
