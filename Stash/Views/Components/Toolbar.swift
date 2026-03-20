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
        let hashtags: [String]
        @Binding var hashtagFilter: String?
        let parentId: UUID?
        let onAddBookmark: () -> Void
        let onAddGroup: () -> Void
        
        @State private var presentBookmarkEditor = false
        @State private var presentGroupEditor = false
        @Environment(\.dismissSearch) private var dismissSearch
        @EnvironmentObject var cabinet: OkamuraCabinet
        
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
                
                Picker("", selection: Binding(
                    get: { hierarchy },
                    set: { newValue in
                        Task { @MainActor in hierarchy = newValue }
                    }
                )) {
                    Label("Descedants", systemImage: "list.bullet.indent")
                        .tag(WorkbenchViewModel.Hierarchy.descendant)
                        .help("Show All Descendants")
                    Label("Children", systemImage: "list.bullet")
                        .tag(WorkbenchViewModel.Hierarchy.child)
                        .help("Show Direct Children")
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
                        presentGroupEditor = true
                        onAddGroup()
                    } label: {
                        Label("Add Group", systemImage: "folder.badge.plus")
                    }
                    .help("Add Group")
                } label: {
                    Label("Add", systemImage: "plus.rectangle.on.rectangle")
                }
                .help("Add Item")
                .popover(isPresented: $presentBookmarkEditor, arrowEdge: .top) {
                    BookmarkEditor(viewModel: BookmarkEditorViewModel(mode: .create(parentId),
                                                                      cabinet: cabinet,
                                                                      dominator: Dominator()))
                    .frame(width: 400)
                }
                .popover(isPresented: $presentGroupEditor, arrowEdge: .top) {
                    GroupEditor(viewModel: GroupEditorViewModel(mode: .create(parentId),
                                                                cabinet: cabinet))
                    .frame(width: 400)
                }
                .onChange(of: presentBookmarkEditor) { _, isPresented in
                    if !isPresented {
                        // Keep the toolbar search UI collapsed after popover closes.
                        dismissSearch()
                        _clearFirstResponder()
                    }
                }
                .onChange(of: presentGroupEditor) { _, isPresented in
                    if !isPresented {
                        // Keep the toolbar search UI collapsed after popover closes.
                        dismissSearch()
                        _clearFirstResponder()
                    }
                }
                
                Menu {
                    Picker("Tag Filter", selection: $hashtagFilter) {
                        Text("None")
                            .tag(String?.none) // Matches the 'nil' state
                        Divider()
                        ForEach(hashtags, id: \.self) { hashtag in
                            Text(hashtag)
                                .tag(String?.some(hashtag))
                        }
                    }
                    .pickerStyle(.inline) // This is crucial: it removes the Picker's own label and shows items directly
                } label: {
                    Label(hashtagFilter ?? "", systemImage: hashtagFilter == nil ? "tag.slash" : "tag")
                        .labelStyle(.titleAndIcon)
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

struct MyImage: View {
    let name: String
    var targetSize: CGFloat = 18
    
    var body: some View {
        let size = CGSize(width: targetSize, height: targetSize)
        let image = Image(name)
        return Image(size: size) { ctx in
            ctx.draw(image, in: CGRect(origin: .zero, size: size))
        }
    }
}
