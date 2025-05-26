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
            return Self.compare(image)
        case .data(let data):
            return Self.compare(NSImage(data: data))
        }
    }
    
    static func compare(_ original: NSImage?) -> NSImage? {
        let flag = original?.tiffRepresentation == emptyFavicon?.tiffRepresentation
        if flag {
            // Create a new image with black background and white "X"
            let size = NSSize(width: 32, height: 32)
            let image = NSImage(size: size)
            
            image.lockFocus()
            
            // Fill black background
            NSColor.black.setFill()
            NSRect(origin: .zero, size: size).fill()
            
            // Draw white "X"
            let text = "1"
            let font = NSFont.systemFont(ofSize: 22, weight: .bold)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.white
            ]
            
            let textSize = text.size(withAttributes: attributes)
            let point = NSPoint(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2
            )
            
            text.draw(at: point, withAttributes: attributes)
            
            image.unlockFocus()
            return image
        }
        return original
    }
}

let emptyFavicon = NSImage(data: NSDataAsset(name: "empty_favicon")!.data)
