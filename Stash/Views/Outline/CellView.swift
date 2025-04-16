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
    
    func update() {
        guard var e = entry else { return }
        guard e.name != title else { return }
        guard !title.trim().isEmpty else {
            title = e.name
            return
        }
        e.name = title
        cabinet.update(entry: e)
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
    
    @State private var hovered: Bool = false
    
    @State private var expanded: Bool
    
    var shouldShowDelete: Bool {
        return hovered && !expanded
    }
    
    var shouldShowCopy: Bool {
        if let _ = viewModel.entry as? Bookmark, hovered, expanded {
            return true
        } else {
            return false
        }
    }
    
    var shouldShowReveal: Bool {
        if let a = viewModel.entry as? Actionable, a.revealable, hovered, expanded {
            return true
        } else {
            return false
        }
    }
    
    var shouldShowActions: Bool {
        return shouldShowDelete || shouldShowCopy || shouldShowReveal
    }
    
    init(viewModel: CellViewModel, expanded: Bool = false) {
        self.viewModel = viewModel
        self.expanded = expanded
    }
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    if let e = viewModel.entry {
                        switch (e.icon) {
                        case .system(let name):
                            Image(systemName: name)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: NSImage.Constant.side2)
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
                }
                .padding(.vertical, 4)
                .onChange(of: focused) { oldValue, newValue in
                    guard newValue != oldValue, !newValue else { return }
                    viewModel.update()
                }
                .onReceive(NotificationCenter.default.publisher(for: .onDoubleTapRowView)) { noti in
                    let entry = noti.object as? any Entry
                    guard entry?.id == viewModel.entry?.id else { return }
                    focused = true
                }
                .onReceive(NotificationCenter.default.publisher(for: .onHoverRowView)) { noti in
                    guard let tuple = noti.object as? (UUID?, Bool), tuple.0 == viewModel.entry?.id else { return }
                    hovered = tuple.1
                }
                .onReceive(NotificationCenter.default.publisher(for: .onCmdKeyChange)) { noti in
                    let flag = (noti.object as? Bool) ?? false
                    expanded = flag
                }
                
                // Bottom border line
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(focused ? Color.primary : Color.clear)
                    .animation(.easeInOut(duration: 0.2), value: focused)
                
                if expanded, let p = path {
                    Text(p)
                        .font(.callout)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    //                        .tint(Color.red)
                    //                        .underline(true, color: Color.secondary)
                    //                        .background(Color.red)
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
                HStack(spacing: 20) {
                    if shouldShowDelete {
                        Button(action: {
                            guard let e = viewModel.entry else { return }
                            cabinet.delete(entry: e)
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .resizable()
                                .frame(width: 20.0, height: 20.0)
                                .foregroundStyle(Color.primary)
                        }
                        .buttonStyle(.plain)
                    }
                    if shouldShowReveal {
                        Button(action: {
                            guard let a = viewModel.entry as? Actionable, a.revealable else { return }
                            a.reveal()
                        }) {
                            Image(systemName: "arrowshape.turn.up.right.circle.fill")
                                .resizable()
                                .frame(width: 20.0, height: 20.0)
                                .foregroundStyle(Color.primary)
                        }
                        .buttonStyle(.plain)
                    }
                    if shouldShowCopy {
                        Button(action: {
                            guard let e = viewModel.entry as? Bookmark else { return }
                            let pasteBoard = NSPasteboard.general
                            pasteBoard.clearContents()
                            pasteBoard.writeObjects([e.url.absoluteString as NSString])
                        }) {
                            Image(systemName: "document.circle.fill")
                                .resizable()
                                .frame(width: 20.0, height: 20.0)
                                .foregroundStyle(Color.primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: gradientColors),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            }
        }
        .padding(.vertical, 10)
    }
    
    var path: AttributedString? {
        guard let bookmark = viewModel.entry as? Bookmark else { return nil }
        
        var prefix: String!
        if let scheme = bookmark.url.scheme {
            prefix = scheme.uppercased()
        } else {
            prefix = "Unknown"
        }
        
        var asPrefix = AttributedString(" \(prefix!) ")
        asPrefix.font = .callout
        asPrefix.foregroundColor = .white
        asPrefix.backgroundColor = NSColor(Color.primary)
        
        var asPath = AttributedString(bookmark.url.absoluteString)
        asPath.font = .callout
        asPath.foregroundColor = .blue
        
        return asPrefix + AttributedString(" ") + asPath
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
