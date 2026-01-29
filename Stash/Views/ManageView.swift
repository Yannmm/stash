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
    @StateObject var workbenchViewModel: WorkbenchViewModel
    @StateObject var groupSectionViewModel: GroupSectionViewModel
    
    
    
    init() {
        _workbenchViewModel = StateObject(
            wrappedValue: WorkbenchViewModel(entries: self.cabinet.storedEntries)
        )
        
        _groupSectionViewModel = StateObject(
            // TODO: fix selection
            wrappedValue: GroupSectionViewModel(selection: nil, entries: self.cabinet.storedEntries)
        )
    }
    
    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            Sidebar()
            .toolbar(removing: .sidebarToggle)      // 🔑 works now
            .navigationSplitViewColumnWidth(
                min: 200,
                ideal: Constant.sidebarWidth,
                max: 400
            )
            .environmentObject(groupSectionViewModel)
        } detail: {
            WorkbenchView()
                .environmentObject(workbenchViewModel)
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
