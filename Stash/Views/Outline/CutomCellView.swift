//
//  CustomTableViewCell.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/18.
//

import AppKit
import SwiftUI
import Kingfisher


//cell?.textField?.stringValue = entry.name
//cell?.textField?.isEditable = true

class CellViewModel: ObservableObject {
    @Published var entry: (any Entry)?
    
    init(entry: (any Entry)? = nil) {
        self.entry = entry
    }
}

enum Focusable: Hashable {
    case none
    case row(id: UUID)
}

extension View {
    func `if`<Content: View>(_ conditional: Bool, content: (Self) -> Content) -> some View {
        if conditional {
            return AnyView(content(self))
        } else {
            return AnyView(self)
        }
    }
}

struct CellContent: View {
    
    @State var viewModel: CellViewModel
    
    var focus: FocusState<Focusable?>.Binding?
    
    var body: some View {
        HStack {
            Label {
                //                Text(entry?.name ?? "")
                //                    .font(.body)
                //                    .foregroundStyle(Color.text)
                
                TextField("123123", text: Binding<String?>(get: { viewModel.entry?.name },
                                                           set: { viewModel.entry?.name = $0 ?? "" }) ?? "")
                .textFieldStyle(.plain)
                .background(Color.clear)
                .if(focus != nil) {
                    $0.focused(focus!, equals: .row(id: viewModel.entry?.id ?? UUID()))
                }
//                .background(Color(NSColor.gridColor))
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
        .background(Color.clear)
    }
}

class CutomCellView: NSTableCellView {
    
    var energy: ((any Entry), FocusState<Focusable?>.Binding)? {
        didSet {
            guard let e = energy else { return }
            hostingView.rootView = CellContent(viewModel: CellViewModel(entry: e.0), focus: e.1)
        }
    }
    
    //    var entry: (any Entry)? {
    //        didSet {
    //            guard let e = entry1 else { return }
    //            hostingView.rootView = CellContent(viewModel: CellViewModel(entry: e))
    //        }
    //    }
    
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
