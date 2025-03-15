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
    
    var title: String
    
    init(entry: (any Entry)? = nil) {
        self.entry = entry
        self.title = entry?.name ?? ""
    }
    
    func update() {
        guard var e = entry else { return }
        guard e.name != title else { return }
        e.name = title
        OkamuraCabinet.shared.upsert(entry: e)
    }
}

// passing data from uikit to swiftui https://www.swiftjectivec.com/events-from-swiftui-to-uikit-and-vice-versa/
extension NSNotification.Name {
    static let tapViewTapped = NSNotification.Name("tapViewTapped")
}

enum Focusable: Hashable {
    case none
    case row(id: UUID)
}

class CellContentViewModel: ObservableObject {
    @Published var allEyesOnMe: Bool = false
}

struct CellContent: View {
    
    @ObservedObject var viewModel: CellViewModel
    
    @FocusState private var focused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                if let e = viewModel.entry {
                    switch (e.icon) {
                    case .system(let name):
                        Image(systemName: name)
                            .foregroundStyle(Color.theme)
                    case .favicon(let url):
                        if let url = url {
                            KFImage.url(url)
                                .loadDiskFileSynchronously()
                                .cacheMemoryOnly()
                                .fade(duration: 0.25)
                                .onSuccess { result in  }
                                .onFailure { error in }
                                .resizable()
                                .frame(width: 16.0, height: 16.0)
                        } else {
                            Image(systemName: "globe")
                                .foregroundStyle(Color.theme)
                        }
                    }
                } else {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(Color.theme)
                }
                
                Rectangle()
                    .frame(width: 1, height: 20)
                    .foregroundColor(focused ? Color.theme : Color.clear)
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
                print("33333 -> \((x.object as! any Entry).id)")
                let id = (x.object as! any Entry).id
                guard id == viewModel.entry?.id else { return }
                focused = true
            }
            
            // Bottom border line
            Rectangle()
                .frame(height: 1)
                .foregroundColor(focused ? Color.theme : Color.clear)
                .animation(.easeInOut(duration: 0.2), value: focused)
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
