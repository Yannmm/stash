//
//  NSImage+Helper.swift
//  Stash
//
//  Created by Rayman on 2025/2/12.
//

import Cocoa
import SwiftUI

extension NSImage {
    static func drawFavicon(from text: String) -> NSImage {
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

extension NSImage {
    func roundCorners(radius: CGFloat) -> NSImage? {
        // Create a new image with the same size as the input image
        let size = self.size
        let rect = NSRect(origin: .zero, size: size)
        
        // Begin an image context to draw the new image
        guard let bitmapRep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width), pixelsHigh: Int(size.height), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 32) else {
            return nil
        }
        
        // Create a new context to draw in the image's rect
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
        
        // Clip the context to a rounded rectangle
        let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
        path.addClip() // Apply the clipping path to the context
        
        // Draw the image in the clipped context
        self.draw(in: rect)
        
        // Restore the previous graphics state
        NSGraphicsContext.restoreGraphicsState()
        
        // Return the new image with rounded corners
        let roundedImage = NSImage(size: size)
        roundedImage.addRepresentation(bitmapRep)
        return roundedImage
    }
}

extension NSImage {
    func tint(color: Color) -> NSImage {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return self
        }
        
        let nsColor = NSColor(color)
        let coloredImage = NSImage(size: size)
        
        coloredImage.lockFocus()
        nsColor.set()
        
        NSGraphicsContext.current?.imageInterpolation = .high
        NSGraphicsContext.current?.compositingOperation = .sourceAtop
        
        let imageRect = NSRect(origin: .zero, size: size)
        NSImage(cgImage: cgImage, size: size).draw(in: imageRect)
        
        imageRect.fill()
        coloredImage.unlockFocus()
        
        return coloredImage
    }
}


extension NSImage {
    enum Constant {
        static let ratio = 1.0
        
        static let side1: Double = 16
        static let size1 = CGSize(width: side1, height: side1)
        static let scaledSize1 = CGSize(width: side1 * ratio, height: side1 * ratio)
        
        static let side2: Double = 20
        static let size2 = CGSize(width: side2, height: side2)
        static let scaledSide2 = side2 * ratio
        static let scaledSize2 = CGSize(width: side2 * ratio, height: side2 * ratio)
    }
}
