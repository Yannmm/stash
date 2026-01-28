//
//  ManageView.swift
//  Stash
//
//  Created by Yan Meng on 2025/12/16.
//

import SwiftUI
import AppKit
import Combine

// Refer to https://dribbble.com/shots/14567500-Bookmark-app-v2

struct ClipTag: Identifiable, Hashable {
    let id = UUID()
    let name: String
}

struct ManageView: View {
    @EnvironmentObject var cabinet: OkamuraCabinet
    @StateObject var viewModel: WorkbenchViewModel
    
    private var groups: Binding<[Group]> {
        Binding(
            get: {
                cabinet.storedEntries.groups
            },
            set: { newGroups in
                // Replace all entries with newGroups + non-Group entries
                //                let nonGroups = cabinet.storedEntries.filter { !($0 is Group) }
                //                cabinet.storedEntries = nonGroups + newGroups
                print(newGroups)
            }
        )
    }
    
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            Sidebar(
                collection: $viewModel.collection,
                groups: groups,
                hashtags: .constant([])
            )
            .navigationSplitViewColumnWidth(min: 200, ideal: Constant.sidebarWidth, max: 400)
        } detail: {
            WorkbenchView()
                .environmentObject(viewModel)
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar(removing: .sidebarToggle)
        .frame(minWidth: Constant.minTotalWidth, minHeight: Constant.minTotalHeight)
    }
}

fileprivate extension ManageView {
    enum Constant {
        static let minTotalWidth: CGFloat = 1000
        static let minTotalHeight: CGFloat = 650
        static let sidebarWidth: CGFloat = 300
    }
}

extension ClipTag {
    static let sampleData: [ClipTag] = [
        ClipTag(name: "Design"),
        ClipTag(name: "Development")
    ]
}

// MARK: - Preview

//#Preview {
//    ManageView()
//}
