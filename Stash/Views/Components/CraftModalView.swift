//
//  CraftModalView.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/25.
//

import SwiftUI

struct CraftModalView: View {
    @Environment(\.dismiss) var dismiss
    @State private var urlString: String = ""
    @State private var pageTitle: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 16) {
            // URL Input Section
            CustomTextField(text: $urlString, placeholder: "Search...")
                            .frame(maxWidth: 200)
            
            // Loading or Result Section
            if isLoading {
                ProgressView()
            } else if !pageTitle.isEmpty {
                Text(pageTitle)
                    .foregroundStyle(.secondary)
            }
            
            //            Spacer()
            
            // Action Buttons
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                
                Button("Save") {
                    // TODO: Implement save action
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(pageTitle.isEmpty)
            }
        }
        .padding()
        .alert("Error", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private func parseURL() async {
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            pageTitle = try await Dominator().fetchWebPageTitle(from: url)
        } catch {
            errorMessage = "Failed to fetch page title: \(error.localizedDescription)"
            pageTitle = ""
        }
    }
}

// https://dribbble.com/shots/20559566-Link-input-with-preview

struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "globe")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .focused($isFocused)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isFocused ? Color.accentColor : Color(nsColor: .separatorColor),
                       lineWidth: isFocused ? 2 : 0.5)
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
            isFocused = true  // Set focus when view appears
        }
    }
}



#Preview {
    CraftModalView()
}
