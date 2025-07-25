//
//  ViewHelper.swift
//  Stash
//
//  Created by Yan Meng on 2025/7/25.
//

import SwiftUI
import Kingfisher

enum ViewHelper {
    @MainActor @ViewBuilder
    static func icon(_ icon: Icon?, side: CGFloat) -> some View {
        if let i = icon {
            switch (i) {
            case .system(let name):
                Image(systemName: name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: side, height: side)
                    .foregroundStyle(Color.theme)
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
}
