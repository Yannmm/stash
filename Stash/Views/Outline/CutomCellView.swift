//
//  CustomTableViewCell.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/18.
//

import AppKit
import SwiftUI
import Kingfisher

struct CellContent: View {
    let entry: (any Entry)?
    
    var body: some View {
        HStack {
            Label {
                Text(entry?.name ?? "")
                    .font(.body)
                    .foregroundStyle(Color.text)
            } icon: {
                if let e = entry {
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
    }
}

class CutomCellView: NSTableCellView {
    
    var entry: (any Entry)? {
        didSet {
            guard let e = entry else { return }
            hostingView.rootView = CellContent(entry: e)
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
        let content = NSHostingView(rootView: CellContent(entry: nil))
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
