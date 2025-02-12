//
//  NSImage+Helper.swift
//  Stash
//
//  Created by Rayman on 2025/2/12.
//

import Cocoa

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
