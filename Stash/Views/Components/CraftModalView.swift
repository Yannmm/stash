//
//  CraftModalView.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/25.
//

import SwiftUI

struct CraftModalView: View {
    @Environment(\.dismiss) var dismiss
    @State private var urlString: String = ""
    @State private var pageTitle: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 16) {
            // URL Input Section
            HStack {
                TextField("Drop or enter URL here", text: $urlString)
                    .textFieldStyle(.roundedBorder)
                    .onDrop(of: [.url], isTargeted: nil) { providers in
                        guard let first = providers.first else { return false }
                        first.loadObject(ofClass: URL.self) { url, error in
                            if let url = url {
                                urlString = url.absoluteString
                            }
                        }
                        return true
                    }
                    .onSubmit {
                        Task { await parseURL() }
                    }
                
                Button {
                    Task { await parseURL() }
                } label: {
                    Image(systemName: "circle.grid.hex")
                        .imageScale(.large)
                }
                .disabled(urlString.isEmpty || isLoading)
            }
            
            // Loading or Result Section
            if isLoading {
                ProgressView()
            } else if !pageTitle.isEmpty {
                Text(pageTitle)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Action Buttons
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                
                Button("Save") {
                    // TODO: Implement save action
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(pageTitle.isEmpty)
            }
        }
        .padding()
        .frame(width: 400, height: 200)
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
    
    private func parseURL() async {
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            pageTitle = try await Dominator().fetchWebPageTitle(from: url)
        } catch {
            errorMessage = "Failed to fetch page title: \(error.localizedDescription)"
            pageTitle = ""
        }
    }
}
#Preview {
    CraftModalView()
}
