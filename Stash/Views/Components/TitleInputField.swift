//
//  TitleInputField.swift
//  Stash
//
//  Created by Rayman on 2025/2/27.
//

import SwiftUI

struct TitleInputField: View {
    @FocusState private var focused: Bool
    @State private var disabled: Bool = true
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: CraftViewModel
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                
                ZStack {
                    // Default icon (shown when no custom icon)
                    if viewModel.icon == nil {
                        Image(systemName: "questionmark.circle.dashed")
                            .resizable()
                            .frame(width: 16, height: 16)
                            .foregroundColor(.secondary)
                            .transition(.opacity)
                    }
                    
                    // Custom icon (shown when available)
                    if let icon = viewModel.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 16, height: 16)
                            .transition(.opacity.combined(with: .scale))
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: viewModel.icon)
                
                Divider()
                TextField("Enter the title here.", text: ($viewModel.title ?? ""))
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
                .frame(height: focused ? 2 : 1)  // Thicker when focused
                .foregroundColor(focused ? Color.theme : Color(nsColor: .separatorColor))
                .animation(.easeInOut(duration: 0.2), value: focused)
        }
        .onChange(of: (viewModel.title ?? "")) { oldValue, newValue in
            if oldValue.isEmpty && !newValue.isEmpty {
                focused = true
                disabled = false
            }
        }
        .onAppear {
            if !(viewModel.title ?? "").isEmpty {
                focused = true
                disabled = false
            }
        }
        .onSubmit {
            viewModel.save()
            dismiss()
        }
    }
}

#Preview {
    //    TitleInputField()
}
