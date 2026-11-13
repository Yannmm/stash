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
    @StateObject var wrapper: GroupSelectionWrapper
    @EnvironmentObject var housekeeper: Housekeeper
    let onOpenSettings: () -> Void
    
    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            Sidebar(viewModel: SidebarViewModel(housekeeper: housekeeper, wrapper: wrapper), onOpenSettings: onOpenSettings)
            .toolbar(removing: .sidebarToggle)      // 🔑 works now
            .navigationSplitViewColumnWidth(
                min: 180,
                ideal: 240,
                max: 350
            )
        } detail: {
            Workbench(viewModel: WorkbenchViewModel(housekeeper: housekeeper, wrapper: wrapper))
        }
        .navigationSplitViewStyle(.prominentDetail)   // 🔑 NOT balanced
        .toolbarBackground(.hidden, for: .windowToolbar)
        .frame(
            minWidth: 600,
            minHeight: 400
        )
        .background(.windowBackground)
    }
}
