//
//  CraftModalView.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/25.
//

import SwiftUI

extension EntryEditor {
    enum Field: Hashable {
        case path
        case title
    }
}

struct EntryEditor: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: EntryEditorViewModel
    
    @FocusState private var focusedField: Field?
    
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
                PathField(loading: $viewModel.loading,
                          icon: $viewModel.icon,
                          path: $viewModel.path,
                          focusedField: $focusedField,)
                    .onSubmit {
                        Task {
                            await viewModel.parse()
                        }
                    }
                TitleField(title: $viewModel.title,
                           icon: viewModel.icon,
                           focusedField: $focusedField,
                           disabled: false)
                    .onSubmit {
                        viewModel.save()
                        dismiss()
                    }
            }
        }
        .padding()
        .background(Color(nsColor: .windowBackgroundColor))
        .alert("Error", isPresented: Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.error?.localizedDescription ?? "")
        }
        .onChange(of: viewModel.focusedField) { _, newValue in
            focusedField = newValue
        }
        .task {
            focusedField = viewModel.focusedField
        }
    }
}
