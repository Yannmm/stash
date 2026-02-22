//
//  Toolbar.swift
//  Stash
//
//  Created by Rayman on 2026/2/6.
//

import SwiftUI

extension ManageView.Workbench {
    struct Toolbar: ToolbarContent {
        @Binding var hierarchy: WorkbenchViewModel.Hierarchy
        let title: String
        let groupCount: Int
        let bookmarkCount: Int
        let onAddBookmark: () -> Void
        let onAddGroup: () -> Void
        
        @State private var presentBookmarkEditor = false
        @Environment(\.dismissSearch) private var dismissSearch
        @EnvironmentObject var dataStore: ManageSelectionStore
        
        var body: some ToolbarContent {
            if #available(macOS 26.0, *) {
                ToolbarItem(placement: .navigation) {
                    Title(title: title, groupCount: groupCount, bookmarkCount: bookmarkCount)
                }
                .sharedBackgroundVisibility(.hidden)
            } else {
                ToolbarItem(placement: .navigation) {
                    Title(title: title, groupCount: groupCount, bookmarkCount: bookmarkCount)
                }
            }
            
            ToolbarItemGroup(placement: .primaryAction) {
                Spacer()
                
                Picker("", selection: $hierarchy) {
                    Label("Children", systemImage: "list.bullet")
                        .tag(WorkbenchViewModel.Hierarchy.child)
                        .help("Show Direct Children")
                    Label("Descedants", systemImage: "list.bullet.indent")
                        .tag(WorkbenchViewModel.Hierarchy.descendant)
                        .help("Show All Descendants")
                }
                .pickerStyle(.segmented)
                
                Menu {
                    Button {
                        presentBookmarkEditor = true
                        onAddBookmark()
                    } label: {
                        Label("Add Bookmark", systemImage: "link.badge.plus")
                    }
                    .help("Add Bookmark")
                    
                    Button {
                        onAddGroup()
                    } label: {
                        Label("Add Group", systemImage: "folder.badge.plus")
                    }
                    .help("Add Group")
                } label: {
                    Label("Add", systemImage: "plus.circle")
                }
                .help("Add Item")
                .popover(isPresented: $presentBookmarkEditor, arrowEdge: .top) {
                    EntryEditor()
                        .frame(width: 400)
                        .environmentObject(EntryEditorViewModel(mode: .create(dataStore.collection?.id),
                                                                cabinet: dataStore.cabinet,
                                                                dominator: Dominator()))
                }
                .onChange(of: presentBookmarkEditor) { _, isPresented in
                    if !isPresented {
                        // Keep the toolbar search UI collapsed after popover closes.
                        dismissSearch()
                        _clearFirstResponder()
                    }
                }
            }
        }
        
        private func _clearFirstResponder() {
            let clear = {
                let _ = (NSApp.keyWindow ?? NSApp.mainWindow)?.makeFirstResponder(nil)
            }
            clear()
            DispatchQueue.main.async { clear() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.02, execute: { clear() })
        }
        
        private struct Title: View {
            let title: String
            let groupCount: Int
            let bookmarkCount: Int
            
            var body: some View {
                HStack {
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.primary)
                    Text(description)
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 6)
            }
            
            private var description: String {
                if groupCount > 0 {
                    return "\(bookmarkCount) Bookmarks | \(groupCount) Groups"
                } else {
                    return "\(bookmarkCount) Bookmarks"
                }
            }
        }
    }
}
