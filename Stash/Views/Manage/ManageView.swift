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
    @EnvironmentObject var cabinet: OkamuraCabinet
    
    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            Sidebar(viewModel: SidebarViewModel(cabinet: cabinet, wrapper: wrapper))
            .toolbar(removing: .sidebarToggle)      // 🔑 works now
            .navigationSplitViewColumnWidth(
                min: 180,
                ideal: 240,
                max: 350
            )
        } detail: {
            Workbench(viewModel: WorkbenchViewModel(cabinet: cabinet, wrapper: wrapper))
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
