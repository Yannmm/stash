//
//  CraftModalView.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/25.
//

import SwiftUI

struct CraftModalView: View {
    @Environment(\.dismiss) var dismiss
    @State private var errorMessage: String?
    @StateObject private var viewModel = CraftViewModel()
    @EnvironmentObject var cabinet: OkamuraCabinet
    @State private var error: Error?
    
    @Binding var anchorId: UUID?
    
    var body: some View {
        VStack(spacing: 0) {
            Text("New Bookmark")
                .font(.headline)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity)
                .background(Color(nsColor: .windowBackgroundColor))
            VStack(spacing: 8) {
                TitleInputField(title: $viewModel.title, icon: $viewModel.icon)
                    .onSubmit {
                        do {
                            try viewModel.save()
                        } catch {
                            self.error = error
                        }
                        dismiss()
                    }
                AddressInputField(viewModel: viewModel)
                
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    if viewModel.savable {
                        Button("Save") {
                            do {
                                try viewModel.save()
                            } catch {
                                self.error = error
                            }
                            dismiss()
                        }
                        .foregroundColor(.accentColor)
                        .disabled(!viewModel.savable)
                        .if(viewModel.savable, content: { $0.buttonStyle(.borderedProminent) })
                    } else {
                        Button("Parse") {
                            Task {
                                do {
                                    try await viewModel.parse()
                                } catch {
                                    viewModel.error = error
                                }
                            }
                        }
                        .disabled(!viewModel.parsable || viewModel.loading)
                        .if(viewModel.parsable && !viewModel.loading, content: { $0.buttonStyle(.borderedProminent) })
                    }
                }
                .padding(.top, 8)
            }
            .padding()
            .background(.white)
        }
        .fixedSize(horizontal: false, vertical: true)
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
            viewModel.anchorId = anchorId
        }
        .alert("Error", isPresented: Binding(
            get: { error != nil },
            set: { x in }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(error?.localizedDescription ?? "")
        }
    }
}
