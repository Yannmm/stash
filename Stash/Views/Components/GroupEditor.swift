//
//  GroupEditor.swift
//  Stash
//
//  Created by Rayman on 2026/3/19.
//

import SwiftUI
import OrderedCollections

struct GroupEditor: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: GroupEditorViewModel
    
    @FocusState private var focusedField: EntryEditor.Field?
    @State private var titleDisabled: Bool = false
    @State private var hashtagDisabled: Bool = false
    
    private var title: String {
        switch viewModel.mode {
        case .create(_):
            return "New Group"
        case .update(_):
            return "Edit Group"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Button("Save") {
                    viewModel.save()
                    dismiss()
                }
                .disabled(!viewModel.savable)
                .if(viewModel.savable, content: { $0.buttonStyle(.borderedProminent) })
            }
            VStack(spacing: 8) {
                TitleField(title: $viewModel.title,
                           icon: viewModel.icon,
                           focusedField: $focusedField,
                           disabled: titleDisabled)
                .onSubmit {
                    guard viewModel.savable else { return }
                    viewModel.save()
                    dismiss()
                }
                HashtagField(
                    existentials: viewModel.housekeeper.$storedEntries
                        .map({
                            OrderedSet($0.map({ $0.hashtags ?? [] }).flatMap({ $0 }))
                        }).eraseToAnyPublisher(),
                    hashtags: $viewModel.hashtags,
                    disabled: hashtagDisabled,
                    onSubmit: {
                        guard viewModel.savable else { return }
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
        .onChange(of: viewModel.savable, { oldValue, newValue in
            hashtagDisabled = !newValue
        })
        .task {
            switch viewModel.mode {
            case .create(_):
                focusedField = .title
                titleDisabled = false
                hashtagDisabled = true
            case .update(_):
                focusedField = .title
                titleDisabled = false
                hashtagDisabled = false
            }
        }
    }
}
