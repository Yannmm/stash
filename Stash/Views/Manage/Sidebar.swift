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
        let onOpenSettings: () -> Void
        
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
            // The list scrolls under the status bar
            .safeAreaInset(edge: .bottom, spacing: 0) {
                StatusBar(onTap: onOpenSettings)
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
    
    /// Sync approach and auth status pinned to the sidebar bottom, opens settings on tap.
    struct StatusBar: View {
        @EnvironmentObject var settingsViewModel: SettingsViewModel
        let onTap: () -> Void
        
        var body: some View {
            if let status = settingsViewModel.synchronizerStatus {
                Button(action: onTap) {
                    HStack(spacing: 6) {
                        Image(systemName: status.symbol)
                            .foregroundStyle(status.failed ? Color(nsColor: .systemRed) : Color.theme)
                            .accessibilityLabel(status.failed ? "Sync error" : "Sync")
                        Text(status.summary)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer(minLength: 0)
                    }
                    .font(.callout)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Open Settings")
                .modifier(StatusBarBackground())
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            }
        }
    }
    
    private struct StatusBarBackground: ViewModifier {
        @ViewBuilder
        func body(content: Content) -> some View {
            if #available(macOS 26, *) {
                content
                    .glassEffect(in: .rect(cornerRadius: 12))
            } else {
                content
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color(NSColor.separatorColor).opacity(0.3), lineWidth: 0.5)
                    )
            }
        }
    }
}
