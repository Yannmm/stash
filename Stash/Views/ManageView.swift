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
    @StateObject var selectionStore: ManageSelectionStore
    
    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            Sidebar(viewModel: SidebarViewModel(selectionStore: selectionStore))
            .toolbar(removing: .sidebarToggle)      // 🔑 works now
            .navigationSplitViewColumnWidth(
                min: 200,
                ideal: Constant.sidebarWidth,
                max: 400
            )
        } detail: {
            WorkbenchView(viewModel: WorkbenchViewModel(selectionStore: selectionStore))
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
