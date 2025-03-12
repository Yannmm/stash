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

enum Focusable: Hashable {
    case none
    case row(id: UUID)
}

class CellContentViewModel: ObservableObject {
    @Published var allEyesOnMe: Bool = false
}

struct CellContent: View {
    
    @StateObject var viewModel: CellViewModel
    
    @FocusState.Binding var focus: Focusable?
    
    @ObservedObject var viewModelxxx: CellContentViewModel
    
    var isFocused: Bool {
        guard let f = $focus.wrappedValue, case .row(let id) = f, let eid = viewModel.entry?.id, id == eid else { return false }
        return true
    }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Label {
                    TextField("123123", text: Binding<String?>(get: { viewModel.entry?.name },
                                                               set: { viewModel.entry?.name = $0 ?? "" }) ?? "")
                    .textFieldStyle(.plain)
                    .background(Color.clear)
                    .focused($focus, equals: .row(id: viewModel.entry?.id ?? UUID()))
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
            .background(viewModelxxx.allEyesOnMe ? Color.red : Color.clear)
        }
    }
}

class CellView: NSTableCellView {
    
    var energy: ((any Entry), FocusState<Focusable?>.Binding)? {
        didSet {
            guard let e = energy else { return }
            
            if hostingView == nil {
                setup(e.0, e.1)
            } else {
                hostingView.rootView = CellContent(viewModel: CellViewModel(entry: e.0), focus: e.1, viewModelxxx: CellContentViewModel())
            }
        }
    }
    
    func xxx(_ flag: Bool) {
        if (hostingView != nil) {
            hostingView.rootView.viewModelxxx.allEyesOnMe = flag
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: CGRectZero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var hostingView: NSHostingView<CellContent>!
    
    
    
    private func setup(_ entry: any Entry, _ focus: FocusState<Focusable?>.Binding) {
        let content = NSHostingView(rootView: CellContent(viewModel: CellViewModel(entry: entry), focus: focus, viewModelxxx: CellContentViewModel()))
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
