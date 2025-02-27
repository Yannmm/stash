//
//  CraftModalView.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/25.
//

import SwiftUI

struct CraftModalView: View {
    @Environment(\.dismiss) var dismiss
    @State var path: URL?
    @State private var errorMessage: String?
    
    @StateObject private var viewModel = CraftViewModel()
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 16) {
                
                HStack(spacing: 6) {
                    Image(systemName: "globe")
                        .resizable()
                        .frame(width: 16, height: 16)
                    Text("1312312")
                }
                .padding(.horizontal, 8)
                AddressInputField(placeholder: "Drop or enter path here.",
                                  text: $path.wrappedValue?.absoluteString ?? "",
                                  viewModel: viewModel)
            }
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                
                Button("Save") {
                    // TODO: Implement save action
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                //                .disabled(pageTitle.isEmpty)
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
}

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
            } else {
                Image(nsImage: viewModel.icon)
                    .resizable()
                    .frame(width: 16, height: 16)
            }
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
                .stroke(focused ? Color.accentColor : Color(nsColor: .separatorColor),
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
    CraftModalView()
}
