//
//  CustomTableViewCell.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/18.
//

import AppKit
import SwiftUI
import Kingfisher
// import Glur

enum Focusable: Hashable {
    case none
    case row(id: UUID)
}

struct CellContent: View {
    
    @EnvironmentObject var cabinet: OkamuraCabinet
    @EnvironmentObject var focusMonitor: FocusMonitor
    @ObservedObject var viewModel: CellViewModel
    @FocusState private var focused: Bool
    @State private var expanded: Bool = false
    @State private var selected: Bool = false
    @State private var deleteAlert: Bool = false
    @State private var ungroupAlert: Bool = false
    @State private var didCopy = false
    
    var shouldShowDelete: Bool {
        return expanded && !focusMonitor.isEditing
    }
    
    var shouldShowUnbox: Bool {
        if let e = viewModel.entry, e.unboxable, expanded, !focusMonitor.isEditing {
            return true
        } else {
            return false
        }
    }
    
    var shouldShowCopy: Bool {
        if let e = viewModel.entry, e.copyable, expanded, !focusMonitor.isEditing {
            return true
        } else {
            return false
        }
    }
    
    var shouldShowReveal: Bool {
        if let e = viewModel.entry, e.revealable, expanded, !focusMonitor.isEditing {
            return true
        } else {
            return false
        }
    }
    
    var shouldShowActions: Bool {
        return shouldShowDelete || shouldShowReveal || shouldShowCopy || shouldShowUnbox
    }
    
    var shouldAddAddress: Bool {
        expanded && (viewModel.entry?.shouldExpand ?? false) && !focusMonitor.isEditing
    }
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                title(shouldAddAddress)
                address()
            }
            Spacer()
            actions()
        }
        .padding(.vertical, 10)
        .padding(.trailing, 10)
        .onAppear {
            viewModel.cabinet = cabinet
            expanded = NSEvent.modifierFlags.containsOnly(.command)
            focused = false
        }
        .onChange(of: focused) { oldValue, newValue in
            focusMonitor.isEditing = newValue
            guard newValue != oldValue, !newValue else { return }
            do {
                try viewModel.update()
            } catch {
                viewModel.error = error
            }
        }
        .onChange(of: focused) { old, new in
            guard !new else { return }
            NotificationCenter.default.post(name: NSControl.textDidEndEditingNotification, object: nil)
        }
        .onChange(of: focusMonitor.isEditing, { _, newValue in
            expanded = false
        })
        .onReceive(NotificationCenter.default.publisher(for: .onDoubleTapRowView)) { noti in
            guard !expanded else { return }
            let entry = noti.object as? any Entry
            guard entry?.id == viewModel.entry?.id else { return }
            focused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .onCmdKeyChange)) { noti in
            guard !focused else { return }
            let flag = (noti.object as? Bool) ?? false
            expanded = flag
        }
        .onReceive(NotificationCenter.default.publisher(for: .onRowViewSelectionChange)) { noti in
            guard let id = noti.userInfo?["id"] as? UUID,
                  let flag = noti.userInfo?["selected"] as? Bool
            else { return }
            if id == viewModel.entry?.id {
                selected = flag
            }
        }
        .alert("Sure to Ungroup?", isPresented: $ungroupAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Confirm", role: .destructive) {
                guard let e = viewModel.entry, e.unboxable else { return }
                do {
                    try viewModel.ungroup(e )
                } catch {
                    viewModel.error = error
                }
            }
        } message: {
            Text("Its content will drop in place.")
        }
        .alert("Sure to Delete \"\(viewModel.entry?.name ?? "")\"?", isPresented: $deleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Confirm", role: .destructive) {
                guard let e = viewModel.entry else { return }
                do {
                    try cabinet.delete(entry: e)
                } catch {
                    viewModel.error = error
                }
            }
        } message: {
            Text("This action cannot be undone. The item will be permanently deleted.")
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.error?.localizedDescription ?? "")
        }
    }
    
    @ViewBuilder
    private func title(_ flag: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: flag ? 2 : 5) {
                icon(flag ? NSImage.Constant.side1:  NSImage.Constant.side2)
                Rectangle()
                    .frame(width: 1, height: 20)
                    .foregroundColor(focused ? Color(NSColor.separatorColor) : Color.clear)
                    .animation(.easeInOut(duration: 0.2), value: focused)
                
//                TextField("Input the title here...", text: $viewModel.title)
//                    .font(flag ? .body : .title2)
//                    .textFieldStyle(.plain)
//                    .background(Color.clear)
//                    .focused($focused)
//                    .layoutPriority(1)
//                    .allowsHitTesting(false)
//                    .truncationMode(.tail)
                

                EmphasisTextField(
                    text: $viewModel.title,
                    font: flag ? NSFont.systemFont(ofSize: NSFont.systemFontSize) : NSFont.systemFont(ofSize: NSFont.systemFontSize + 5),
                    suggestions: getSuggestions(),
                    onSuggestionSelected: { suggestion in
                        // Handle suggestion selection if needed
                        print("Selected suggestion: \(suggestion)")
                    }
                )
                .focused($focused)
            }
            .padding(.vertical, flag ? 0 : 4)
            
            if !flag {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(focused ? Color.primary : Color.clear)
                    .animation(.easeInOut(duration: 0.2), value: focused)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: flag)
    }
    
    // Helper function to get suggestions from existing entries
    private func getSuggestions() -> [String] {
        var suggestions: Set<String> = []
        
        // Add all bookmark names and group names
        for entry in cabinet.storedEntries {
            suggestions.insert(entry.name)
        }
        
        // Add some common hashtags for better UX
        suggestions.insert("work")
        suggestions.insert("personal")
        suggestions.insert("important")
        suggestions.insert("todo")
        suggestions.insert("reference")
        suggestions.insert("project")
        suggestions.insert("research")
        suggestions.insert("tutorial")
        suggestions.insert("documentation")
        suggestions.insert("news")
        suggestions.insert("social")
        suggestions.insert("shopping")
        suggestions.insert("entertainment")
        suggestions.insert("finance")
        suggestions.insert("health")
        suggestions.insert("travel")
        suggestions.insert("food")
        suggestions.insert("technology")
        suggestions.insert("design")
        suggestions.insert("music")
        
        let result = Array(suggestions).sorted()
        print("DEBUG: getSuggestions() returned \(result.count) suggestions: \(result)")
        return result
    }
    
    @ViewBuilder
    private func icon(_ side: CGFloat) -> some View {
        if let e = viewModel.entry {
            switch (e.icon) {
            case .system(let name):
                Image(systemName: name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: side, height: side)
                    .foregroundStyle(Color.primary)
            case .favicon(let url):
                KFImage.url(url)
                    .appendProcessor(EmptyFaviconReplacer(url: url))
                    .scaleFactor(NSScreen.main?.backingScaleFactor ?? 2)
                    .cacheOriginalImage()
                    .loadDiskFileSynchronously()
                    .onSuccess { result in }
                    .onFailure { error in }
                    .onFailureImage(NSImage.drawFavicon(from: url.firstDomainLetter))
                    .resizable()
                    .frame(width: side, height: side)
            case .local(let url):
                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: side, height: side)
            }
        }
    }
    
    @ViewBuilder
    private func address() -> some View {
        ZStack {
            if shouldAddAddress, let tuple2 = bookmarkAccessible {
                Button {
                    tuple2.1.open()
                    do {
                        try cabinet.asRecent(tuple2.1)
                    } catch {
                        viewModel.error = error
                    }
                } label: {
                    HStack {
                        Text(tuple2.0)
                            .truncationMode(.middle)
                            .lineLimit(2)
                        Spacer()
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .fixedSize(horizontal: false, vertical: true)
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: expanded)
    }

    @ViewBuilder
    private func actions() -> some View {
        ZStack {
            if shouldShowActions {
                HStack(spacing: 10) {
                    Button(action: {
                        deleteAlert = true
                    }) {
                        Image(systemName: "trash.circle")
                            .resizable()
                            .frame(width: 18.0, height: 18.0)
                    }
                    .buttonStyle(.borderless)
                    .help("Delete item")
                    if shouldShowUnbox {
                        Button(action: {
                            ungroupAlert = true
                        }) {
                            Image(systemName: "archivebox.circle")
                                .resizable()
                                .frame(width: 18.0, height: 18.0)
                        }
                        .buttonStyle(.borderless)
                        .help("Ungroup the content.")
                    }
                    if shouldShowReveal {
                        Button(action: {
                            guard let e = viewModel.entry, e.revealable else { return }
                            e.reveal()
                        }) {
                            Image(systemName: "folder.circle")
                                .resizable()
                                .frame(width: 18.0, height: 18.0)
                        }
                        .buttonStyle(.borderless)
                        .help("Reveal in Finder")
                    }
                    if shouldShowCopy {
                        Button(action: {
                            guard let e = viewModel.entry, e.copyable, let url = e.valueToCopy else { return }
                            let pasteBoard = NSPasteboard.general
                            pasteBoard.clearContents()
                            pasteBoard.writeObjects([url as NSString])
                            didCopy = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                didCopy = false
                            }
                        }) {
                            Image(systemName: "rectangle.on.rectangle.circle")
                                .resizable()
                                .frame(width: 18.0, height: 18.0)
                                .if(didCopy, content: { $0.foregroundColor(.green) })
                        }
                        .buttonStyle(.borderless)
                        .help("Copy path")
                    }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: expanded)
    }
    
    private var bookmarkAccessible: (AttributedString, Bookmark)? {
        guard let bookmark = viewModel.entry as? Bookmark else { return nil }
        
        let components = URLComponents(url: bookmark.url, resolvingAgainstBaseURL: false)
        let scheme = components?.scheme
        
        var prefix: String!
        if let s = scheme {
            prefix = "\(s)://"
        } else {
            prefix = "Unknown"
        }
        
        var asPrefix = AttributedString("\(prefix!)")
        asPrefix.font = .body
        asPrefix.foregroundColor = .white
        asPrefix.backgroundColor = NSColor(Color.primary)
        
        guard var path = components?.string else { return nil }
        path = path.replacingOccurrences(of: prefix, with: "")
        var asPath = AttributedString(path)
        asPath.font = .body
        asPath.foregroundColor = selected ? .white : .linkColor
        
        return (asPrefix + AttributedString(" ") + asPath, bookmark)
    }
    
    var gradientColors: [Color] {
        if shouldShowDelete {
            return [Color(NSColor.gridColor).opacity(0.3),
                    Color(NSColor.gridColor).opacity(0.8),
                    Color(NSColor.gridColor).opacity(0.3)]
        } else if shouldShowDelete || shouldShowReveal {
            return [.white.opacity(0.3),
                    .white.opacity(0.8),
                    .white.opacity(0.3)]
        } else {
            return []
        }
    }
}
