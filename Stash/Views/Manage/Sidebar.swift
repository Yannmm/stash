//
//  CollectionList.swift
//  Stash
//
//  Created by Yan Meng on 2025/12/16.
//

import SwiftUI
import AppKit

extension ManageView {
    struct Sidebar: View {
        @StateObject var viewModel: SidebarViewModel
        
        var body: some View {
            ScrollView {
                LazyVStack(spacing: 0) {
                    GroupSection.Row(
                        row: viewModel.rootRow,
                        icon: "infinity",
                        drag: .constant(nil),
                        dragTarget: .constant(nil),
                        onToggleExpansion: {},
                        onTap: {
                            viewModel.wrapper.selection = nil
                        },
                        onDrop: { _, __, ___ in
                            
                        },
                        onDelete: { _ in },
                        onUngroup: { _ in }) { _, __ in
                            return .none
                        }
                    GroupSection()
                }
                .padding(.horizontal, 16)
            }
            .environmentObject(viewModel)
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
}