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
            return customImage()
        }
        return original
    }
    
    private func customImage() -> NSImage {
        // Create a new image with black background and white "X"
        let size = NSSize(width: 32, height: 32)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // Create rounded rect path
        let cornerRadius: CGFloat = 6
        let path = NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: cornerRadius, yRadius: cornerRadius)
        
        // Fill black background with rounded corners
        NSColor.black.setFill()
        path.fill()
        
        // Draw white "X"
        var text = "?"
        if let comps = url.path.split(separator: "/").first?.lowercased() {
            text = (comps.hasPrefix("www.") ? String(comps.dropFirst(4).first ?? "?") : String(comps.first ?? "?")).uppercased()
        }
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
}

let emptyFavicon = NSImage(data: NSDataAsset(name: "empty_favicon")!.data)
