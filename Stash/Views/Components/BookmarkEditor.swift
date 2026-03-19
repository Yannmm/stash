//
//  CraftModalView.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/25.
//

import SwiftUI
import OrderedCollections

struct BookmarkEditor: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: BookmarkEditorViewModel
    
    @FocusState private var focusedField: EntryEditor.Field?
    @State private var titleDisabled: Bool = false
    @State private var hashtagDisabled: Bool = false
    
    private var title: String {
        switch viewModel.mode {
        case .create(_):
            return "New Bookmark"
        case .update(_):
            return "Edit Bookmark"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
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
                    switch viewModel.progress {
                    case .parsable(let flag):
                        if flag {
                            viewModel.parse()
                        }
                    case .savable(let flag):
                        if flag {
                            viewModel.save()
                            dismiss()
                        }
                    }
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
                HashtagField(
                    existentials: viewModel.cabinet.$storedEntries
                        .map({
                            OrderedSet($0.map({ $0.hashtags ?? [] }).flatMap({ $0 }))
                        }).eraseToAnyPublisher(),
                    hashtags: $viewModel.hashtags,
                    disabled: hashtagDisabled,
                    onSubmit: {
                        guard viewModel.progress == .savable(true) else { return }
                        viewModel.save()
                        dismiss()
                    }
                )
                
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
                if focusedField == .path {
                    focusedField = .title
                    titleDisabled = false
                    hashtagDisabled = false
                }
            }
        }
        .task {
            switch viewModel.mode {
            case .create(_):
                focusedField = .path
                titleDisabled = true
                hashtagDisabled = true
            case .update(_):
                focusedField = .title
                titleDisabled = false
                hashtagDisabled = false
            }
        }
    }
}
