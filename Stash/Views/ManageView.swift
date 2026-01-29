//
//  ManageView.swift
//  Stash
//
//  Created by Yan Meng on 2025/12/16.
//

import SwiftUI
import AppKit
import Combine

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
        NavigationSplitView(columnVisibility: .constant(.all)) {
            Sidebar(
                collection: $viewModel.collection,
                groups: groups,
                hashtags: .constant([])
            )
            .toolbar(removing: .sidebarToggle)      // 🔑 works now
            .navigationSplitViewColumnWidth(
                min: 200,
                ideal: Constant.sidebarWidth,
                max: 400
            )
        } detail: {
            WorkbenchView()
                .environmentObject(viewModel)
        }
        .navigationSplitViewStyle(.prominentDetail)   // 🔑 NOT balanced
        .toolbarBackground(.hidden, for: .windowToolbar)
        .frame(
            minWidth: Constant.minTotalWidth,
            minHeight: Constant.minTotalHeight
        )
        .background(.windowBackground)
        
    }
}

fileprivate extension ManageView {
    enum Constant {
        static let minTotalWidth: CGFloat = 1000
        static let minTotalHeight: CGFloat = 650
        static let sidebarWidth: CGFloat = 300
    }
}

// MARK: - Preview

//#Preview {
//    ManageView()
//}
