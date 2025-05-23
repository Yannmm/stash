//
//  EmptyFaviconReplacer.swift
//  Stash
//
//  Created by Rayman on 2025/5/23.
//

import Kingfisher
import AppKit

struct EmptyFaviconReplacer: ImageProcessor {
    var identifier: String { "com.rendezvousauoaradis.stash.empty-favicon-replacer" }
    
    func process(item: Kingfisher.ImageProcessItem, options: Kingfisher.KingfisherParsedOptionsInfo) -> Kingfisher.KFCrossPlatformImage? {
        switch item {
        case .image(let image):
            return Self.compare(image)
        case .data(let data):
            return Self.compare(NSImage(data: data))
        }
    }
    
    static func compare(_ original: NSImage?) -> NSImage? {
        if let asset = NSDataAsset(name: "empty_favicon") {
            let empty = NSImage(data: asset.data)
            let flag = original?.tiffRepresentation == empty?.tiffRepresentation
            if flag {
                return NSImage(systemSymbolName: "globe", accessibilityDescription: nil)
            }
        }
        return original
    }
}
