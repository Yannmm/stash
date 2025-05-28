//
//  EmptyFaviconReplacer.swift
//  Stash
//
//  Created by Rayman on 2025/5/23.
//

import Kingfisher
import AppKit

struct EmptyFaviconReplacer: ImageProcessor {
    let url: URL
    
    var identifier: String { "com.rendezvousauoaradis.stash.empty-favicon-replacer" }
    
    func process(item: Kingfisher.ImageProcessItem, options: Kingfisher.KingfisherParsedOptionsInfo) -> Kingfisher.KFCrossPlatformImage? {
        switch item {
        case .image(let image):
            return compare(image)
        case .data(let data):
            return compare(NSImage(data: data))
        }
    }
    
    private func compare(_ original: NSImage?) -> NSImage? {
        let flag = original?.tiffRepresentation == emptyFavicon?.tiffRepresentation
        if flag {
            return NSImage.drawFavicon(from: url.firstDomainLetter)
        }
        return original
    }
}

let emptyFavicon = NSImage(data: NSDataAsset(name: "empty_favicon")!.data)
