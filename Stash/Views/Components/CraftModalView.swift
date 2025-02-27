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

#Preview {
    CraftModalView()
}
