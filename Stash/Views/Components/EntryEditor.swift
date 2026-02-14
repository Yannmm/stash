//
//  CraftModalView.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/25.
//

import SwiftUI

struct EntryEditor: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.dismissSearch) private var dismissSearch
    @StateObject private var viewModel = CraftViewModel()
    @EnvironmentObject var cabinet: OkamuraCabinet
    @Binding var anchorId: UUID?
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("New Bookmark")
                    .font(.headline)
                Spacer()
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
            VStack(spacing: 8) {
                AddressInputField(loading: $viewModel.loading, icon: $viewModel.icon, path: $viewModel.path)
                    .onSubmit {
                        Task {
                            await viewModel.parse()
                        }
                    }
                TitleInputField(title: $viewModel.title, icon: $viewModel.icon)
                    .onSubmit {
                        viewModel.save()
                        dismiss()
                    }
            }
        }
        .padding()
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            //            viewModel.cabinet = cabinet
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
