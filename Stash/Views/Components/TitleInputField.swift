//
//  TitleInputField.swift
//  Stash
//
//  Created by Rayman on 2025/2/27.
//

import SwiftUI

struct TitleInputField: View {
    @FocusState private var focused: Bool
    @Environment(\.dismiss) var dismiss
    @State private var disabled: Bool = true
    var title: Binding<String?>
    @Binding var icon: NSImage?
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                ZStack {
                    if let i = icon {
                        Image(nsImage: i)
                            .resizable()
                            .frame(width: 16, height: 16)
                            .transition(.opacity.combined(with: .scale))
                    } else {
                        Image(systemName: "questionmark.circle.dashed")
                            .resizable()
                            .frame(width: 16, height: 16)
                            .foregroundColor(.secondary)
                            .transition(.opacity)
                    }
                    
                }
                .animation(.easeInOut(duration: 0.3), value: icon)
                Divider()
                TextField("Title Will Be Here.", text: title ?? "")
                    .textFieldStyle(.plain)
                    .focused($focused)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.clear)
            .cornerRadius(6)
            .focusable()
            .disabled(disabled)
            
            // Bottom border line
            Rectangle()
                .frame(height: 1)  // Thicker when focused
                .foregroundColor(focused ? Color.primary : Color(nsColor: .separatorColor))
                .animation(.easeInOut(duration: 0.2), value: focused)
        }
        .onChange(of: title.wrappedValue ?? "") { _, newValue in
            if !newValue.isEmpty {
                focused = true
                disabled = false
            } else {
                focused = false
                disabled = true
            }
        }
    }
}
