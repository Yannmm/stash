//
//  CustomTableViewCell.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/18.
//

import AppKit
import SwiftUI
import Kingfisher

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

// passing data from uikit to swiftui https://www.swiftjectivec.com/events-from-swiftui-to-uikit-and-vice-versa/
extension NSNotification.Name {
    static let tapViewTapped = NSNotification.Name("tapViewTapped")
    static let onHoverRowView = NSNotification.Name("onHoverRowView")
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
    
    @State private var deletable: Bool = false
    
    var body: some View {
        HStack {
            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    if let e = viewModel.entry {
                        switch (e.icon) {
                        case .system(let name):
                            Image(systemName: name)
                                .resizable()
                                .frame(width: 16.0, height: 16.0)
                                .foregroundStyle(Color.primary)
                        case .favicon(let url):
                            KFImage.url(url)
                                .loadDiskFileSynchronously()
                                .cacheMemoryOnly()
                                .fade(duration: 0.25)
                                .onSuccess { result in  }
                                .onFailure { error in }
                                .resizable()
                                .frame(width: 16.0, height: 16.0)
                        case .local(let url):
                            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 16.0)
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
                        .textFieldStyle(.plain)
                        .background(Color.clear)
                        .focused($focused)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .onChange(of: focused) { oldValue, newValue in
                    guard newValue != oldValue, !newValue else { return }
                    viewModel.update()
                }
                .onReceive(NotificationCenter.default.publisher(for: .tapViewTapped)) { x in
                    let id = (x.object as! any Entry).id
                    guard id == viewModel.entry?.id else { return }
                    focused = true
                }
                .onReceive(NotificationCenter.default.publisher(for: .onHoverRowView)) { x in
                    guard let tuple = x.object as? (UUID?, Bool), tuple.0 == viewModel.entry?.id else { return }
                    deletable = tuple.1
                }
                
                // Bottom border line
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(focused ? Color.primary : Color.clear)
                    .animation(.easeInOut(duration: 0.2), value: focused)
            }
            .onAppear {
                viewModel.cabinet = cabinet
            }
            Spacer()
            if deletable {
                Button(action: {
                    guard let e = viewModel.entry else { return }
                    cabinet.delete(entry: e)
                }) {
                    Image(systemName: "minus.circle.fill")
                        .resizable()
                        .frame(width: 16.0, height: 16.0)
                        .foregroundStyle(Color.primary)
                }
                .buttonStyle(.plain)
                
            }
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
