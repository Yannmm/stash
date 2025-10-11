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

struct HeightSignal: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

struct VisibleRangeSignal: PreferenceKey {
    static var defaultValue: [Int: ClosedRange<CGFloat>] = [:]
    static func reduce(value: inout [Int: ClosedRange<CGFloat>], nextValue: () -> [Int: ClosedRange<CGFloat>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
    
    /// Compute which indexes are fully visible inside the container height
    static func computeVisibleRange(from values: [Int: ClosedRange<CGFloat>], containerHeight: CGFloat) -> Range<Int> {
        let visible = values
            .filter { $0.value.lowerBound >= 0 && $0.value.upperBound <= containerHeight }
            .map { $0.key }
            .sorted()
        
        if let first = visible.first, let last = visible.last {
            return first..<last+1
        } else {
            return 0..<0
        }
    }
}
