//
//  CraftModalView.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/25.
//

import SwiftUI

struct CraftModalView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = CraftViewModel()
    @EnvironmentObject var cabinet: OkamuraCabinet
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
                        viewModel.save()
                        dismiss()
                    }
                AddressInputField(loading: $viewModel.loading, icon: $viewModel.icon, path: $viewModel.path)
                    .onSubmit {
                        Task {
                            await viewModel.parse()
                        }
                    }
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    if viewModel.savable {
                        Button("Save") {
                            viewModel.save()
                            dismiss()
                        }
                        .foregroundColor(.accentColor)
                        .disabled(!viewModel.savable)
                        .if(viewModel.savable, content: { $0.buttonStyle(.borderedProminent) })
                    } else {
                        Button("Parse") {
                            Task {
                                await viewModel.parse()
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
        .onAppear {
            viewModel.cabinet = cabinet
            viewModel.anchorId = anchorId
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.error?.localizedDescription ?? "")
        }
    }
}
