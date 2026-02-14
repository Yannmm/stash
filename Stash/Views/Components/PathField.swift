//
//  AddressInputField.swift
//  Stash
//
//  Created by Rayman on 2025/2/27.
//

import SwiftUI

struct PathField: View {
    @FocusState private var focused: Bool
    @Binding var loading: Bool
    @Binding var icon: Icon?
    @Binding var path: String?
    
    var body: some View {
        HStack(spacing: 6) {
            iconView
            Divider()
            TextField("Enter url or file path", text: $path ?? "")
                .textFieldStyle(.plain)
                .focused($focused)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .cornerRadius(6)
        .background(Color(nsColor: .controlBackgroundColor))
        .overlay {
            // Base border (matches standard macOS separators)
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                .allowsHitTesting(false)
            
            // macOS-style focus ring (accent color + subtle glow)
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    Color(nsColor: .keyboardFocusIndicatorColor)
                        .opacity(focused ? 1 : 0),
                    lineWidth: 3
                )
            // Start slightly "outside", then settle to final ring.
                .padding(focused ? -1 : -4)
                .scaleEffect(focused ? 1.0 : 1.06)
                .shadow(
                    color: Color(nsColor: .keyboardFocusIndicatorColor)
                        .opacity(focused ? 1 : 0),
                    radius: focused ? 3 : 0
                )
                .allowsHitTesting(false)
        }
        .animation(.spring(response: 0.20, dampingFraction: 0.78, blendDuration: 0.10), value: focused)
        .onAppear {
            focused = true
        }
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
