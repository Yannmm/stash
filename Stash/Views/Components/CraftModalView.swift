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
    @EnvironmentObject var cabinet: OkamuraCabinet
    
    var body: some View {
        VStack(spacing: 16) {
            TitleInputField(viewModel: viewModel)
            
            AddressInputField(placeholder: "Drop or enter path to create a new bookmark.",
                              text: $path.wrappedValue?.absoluteString ?? "",
                              viewModel: viewModel)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                
                Button("Save") {
                    viewModel.save()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
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
        .onAppear {
            viewModel.cabinet = cabinet
        }
    }
}

#Preview {
//    CraftModalView()
}
