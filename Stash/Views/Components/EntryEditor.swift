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
    @State private var titleDisabled: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("New Bookmark")
                    .font(.headline)
                Spacer()
                switch viewModel.progress {
                case .parsable(let enabled):
                    Button("Parse") {
                        viewModel.parse()
                    }
                    .disabled(!(enabled && !viewModel.loading))
                    .if(enabled && !viewModel.loading, content: { $0.buttonStyle(.borderedProminent) })
                case .savable(let enabled):
                    Button("Save") {
                        viewModel.save()
                        dismiss()
                    }
                    .disabled(!enabled)
                    .if(enabled, content: { $0.buttonStyle(.borderedProminent) })
                }
            }
            VStack(spacing: 8) {
                PathField(loading: $viewModel.loading,
                          icon: $viewModel.icon,
                          path: $viewModel.path,
                          focusedField: $focusedField)
                .onSubmit {
                    guard viewModel.progress == .parsable(true) else { return }
                    viewModel.parse()
                }
                TitleField(title: $viewModel.title,
                           icon: viewModel.icon,
                           focusedField: $focusedField,
                           disabled: titleDisabled)
                .onSubmit {
                    guard viewModel.progress == .savable(true) else { return }
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
        // State moifiers
        .onChange(of: viewModel.progress) { oldValue, newValue in
            switch newValue {
            case .parsable(_):
                break
            case .savable(_):
                focusedField = .title
                titleDisabled = false
            }
        }
        .task {
            switch viewModel.mode {
            case .create(_):
                focusedField = .path
                titleDisabled = true
            case .update(_):
                focusedField = .title
                titleDisabled = false
            }
        }
    }
}
