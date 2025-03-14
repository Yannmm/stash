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
    
    init(entry: (any Entry)? = nil) {
        self.entry = entry
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
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Label {
                    TextField("123123", text: Binding<String?>(get: { viewModel.entry?.name },
                                                               set: { viewModel.entry?.name = $0 ?? "" }) ?? "")
                    .textFieldStyle(.plain)
                    .background(Color.clear)
                    .focused($focused)
                } icon: {
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
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 0))
            }
            .background(focused ? Color.red : Color.clear)
            .onChange(of: focused) { oldValue, newValue in
                print("0000 ->\(oldValue) xxx \(newValue)")
            }
            .onReceive(NotificationCenter.default.publisher(for: .tapViewTapped)) { x in
                print("33333 -> \((x.object as! any Entry).id)")
                let id = (x.object as! any Entry).id
                guard id == viewModel.entry?.id else { return }
                focused = true
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
