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

class CellViewModel: ObservableObject {
    @Published var entry: (any Entry)?
    
    var cabinet: OkamuraCabinet!
    
    @Published var title: String
    
    init(entry: (any Entry)? = nil) {
        self.entry = entry
        self.title = entry?.name ?? ""
    }
    
    func update() throws {
        guard var e = entry else { return }
        guard e.name != title else { return }
        guard !title.trim().isEmpty else {
            title = e.name
            return
        }
        e.name = title
        try cabinet.update(entry: e)
    }
}

enum Focusable: Hashable {
    case none
    case row(id: UUID)
}

class CellContentViewModel: ObservableObject {
    @Published var allEyesOnMe: Bool = false
}

struct CellContent: View {
    
    @EnvironmentObject var cabinet: OkamuraCabinet
    
    @ObservedObject var viewModel: CellViewModel
    
    @FocusState private var focused: Bool
    
    @State private var expanded: Bool
    @State private var error: Error?
    @State private var deleteAlert: Bool = false
    @State private var didCopy = false
    
    var shouldShowDelete: Bool {
        return expanded
    }
    
    var shouldShowCopy: Bool {
        if let _ = viewModel.entry as? Bookmark, expanded {
            return true
        } else {
            return false
        }
    }
    
    var shouldShowReveal: Bool {
        if let a = viewModel.entry as? Actionable, a.revealable, expanded {
            return true
        } else {
            return false
        }
    }
    
    var shouldShowActions: Bool {
        return shouldShowDelete || shouldShowReveal || shouldShowCopy
    }
    
    init(viewModel: CellViewModel, expanded: Bool = false) {
        self.viewModel = viewModel
        self.expanded = expanded
    }
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    if let e = viewModel.entry {
                        switch (e.icon) {
                        case .system(let name):
                            Image(systemName: name)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: NSImage.Constant.side2, height: NSImage.Constant.side2)
                                .foregroundStyle(Color.primary)
                        case .favicon(let url):
                            KFImage.url(url)
                                .loadDiskFileSynchronously()
                                .cacheMemoryOnly()
                                .onSuccess { result in  }
                                .onFailure { error in }
                                .onFailureImage(NSImage(systemSymbolName: "globe", accessibilityDescription: nil))
                                .resizable()
                                .frame(width: NSImage.Constant.side2, height: NSImage.Constant.side2)
                        case .local(let url):
                            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                            //                                .frame(width: NSImage.Constant.side2)
                                .frame(width: NSImage.Constant.side2, height: NSImage.Constant.side2)
                        }
                    } else {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(Color.primary)
                    }
                    
                    
                    Rectangle()
                        .frame(width: 1, height: 20)
                        .foregroundColor(focused ? Color.primary : Color.clear)
                        .animation(.easeInOut(duration: 0.2), value: focused)
                    
                    TextField("Input the title here...", text: $viewModel.title)
                        .font(.title3)
                        .textFieldStyle(.plain)
                        .background(Color.clear)
                        .focused($focused)
                        .layoutPriority(1)
                        .allowsHitTesting(false)
                        .truncationMode(.tail)
                }
                .padding(.vertical, 4)
                .onChange(of: focused) { oldValue, newValue in
                    guard newValue != oldValue, !newValue else { return }
                    do {
                        try viewModel.update()
                    } catch {
                        self.error = error
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .onDoubleTapRowView)) { noti in
                    let entry = noti.object as? any Entry
                    guard entry?.id == viewModel.entry?.id else { return }
                    focused = true
                }
                .onReceive(NotificationCenter.default.publisher(for: .onCmdKeyChange)) { noti in
                    let flag = (noti.object as? Bool) ?? false
                    expanded = flag
                }
                .onChange(of: focused) { old, new in
                    guard !new else { return }
                    NotificationCenter.default.post(name: NSControl.textDidEndEditingNotification, object: nil)
                }
                
                // Bottom border line
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(focused ? Color.primary : Color.clear)
                    .animation(.easeInOut(duration: 0.2), value: focused)
                
                if expanded, let tuple2 = bookmarkAccessible {
                    Button {
                        tuple2.1.open()
                        do {
                            try cabinet.asRecent(tuple2.1)
                        } catch {
                            self.error = error
                        }
                    } label: {
                        HStack {
                            Text(tuple2.0)
                                .font(.callout)
                                .lineLimit(nil)
                                .multilineTextAlignment(.leading)
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
                }
            }
            .onAppear {
                viewModel.cabinet = cabinet
            }
            Spacer()
            
            if shouldShowActions {
                HStack(spacing: 10) {
                    Button(action: {
                        deleteAlert = true
                    }) {
                        Image(systemName: "trash.circle")
                            .resizable()
                            .frame(width: 20.0, height: 20.0)
                    }
                    .buttonStyle(.borderless)
                    .help("Delete item")
                    if shouldShowReveal {
                        Button(action: {
                            guard let a = viewModel.entry as? Actionable, a.revealable else { return }
                            a.reveal()
                        }) {
                            Image(systemName: "archivebox.circle")
                                .resizable()
                                .frame(width: 20.0, height: 20.0)
                        }
                        .buttonStyle(.borderless)
                        .help("Reveal in Finder")
                    }
                    if shouldShowCopy {
                        Button(action: {
                            guard let e = viewModel.entry as? Bookmark else { return }
                            let pasteBoard = NSPasteboard.general
                            pasteBoard.clearContents()
                            pasteBoard.writeObjects([e.url.absoluteString as NSString])
                            didCopy = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                didCopy = false
                            }
                        }) {
                            if didCopy {
                                Image(systemName: "checkmark.circle.fill")
                                    .resizable()
                                    .frame(width: 20.0, height: 20.0)
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "rectangle.on.rectangle.circle")
                                    .resizable()
                                    .frame(width: 20.0, height: 20.0)
                            }
                        }
                        .buttonStyle(.borderless)
                        .help("Copy path")
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.leading, 10)
        .alert("Sure to delete?", isPresented: $deleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Confirm", role: .destructive) {
                guard let e = viewModel.entry else { return }
                do {
                    try cabinet.delete(entry: e)
                } catch {
                    self.error = error
                }
            }
        } message: {
            Text("This action cannot be undone. The item will be permanently deleted.")
        }
        .alert("Error", isPresented: Binding(
            get: { error != nil },
            set: { x in }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(error?.localizedDescription ?? "")
        }
    }
    
    var bookmarkAccessible: (AttributedString, Bookmark)? {
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
        asPrefix.font = .callout
        asPrefix.foregroundColor = .white
        asPrefix.backgroundColor = NSColor(Color.primary)
        
        guard let path = components?.string else { return nil }
        var asPath = AttributedString(path.replacingOccurrences(of: prefix, with: ""))
        asPath.font = .callout
        asPath.foregroundColor = .linkColor
        
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

class CellView: NSTableCellView {
    
    var entry: (any Entry)? {
        didSet {
            hostingView.rootView = CellContent(viewModel: CellViewModel(entry: entry))
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: CGRectZero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var hostingView: NSHostingView<CellContent>!
    
    
    
    private func setup() {
        let content = NSHostingView(rootView: CellContent(viewModel: CellViewModel()))
        self.hostingView = content
        content.sizingOptions = .minSize
        self.addSubview(content)
        
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: self.topAnchor),
            content.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            content.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }
}
