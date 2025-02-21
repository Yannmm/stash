//
//  AppDelegate+NSMenu.swift
//  Stash
//
//  Created by Rayman on 2025/2/10.
//

import AppKit
import SwiftUI
import Kingfisher

extension AppDelegate {
    @MainActor
    func generateMenu(from entries: [any Entry]) -> NSMenu {
        return g(entries: entries)
    }
    
    @MainActor
    private func g(entries: [any Entry], isRoot: Bool = true) -> NSMenu {
        //        let u1 = URL(string: "https://www.figma.com/design/G9CcLvgYkfCXaZGKE0lhNd/Insight-lite-app-UI-design?node-id=12-316&p=f&t=uCeb0t4trYsXRro1-0")
        
        let menu = NSMenu()
        entries.forEach { e in
            let item = CustomMenuItem(title: e.name, action: #selector(action(_:)), keyEquivalent: "", with: e)
            
            switch e.icon {
            case Icon.system(let name):
                item.image = NSImage(systemSymbolName: name, accessibilityDescription: nil)
            case Icon.favicon(let url):
                setFavicon(url, item)
            }
            
            if !(e.children ?? []).isEmpty {
                let submenu = g(entries: e.children ?? [], isRoot: false)
                item.submenu = submenu
            }
            menu.addItem(item)
        }
        if (isRoot) {
            menu.addItem(NSMenuItem.separator())
            
            let ooo = NSMenuItem(title: "Drag & Drop", action: #selector(togglePopover), keyEquivalent: "G")
            
            menu.addItem(ooo)
        }
        return menu
    }
    
    @objc private func action(_ sender: CustomMenuItem) {
        sender.object?.open()
    }
    
    @MainActor
    private func setFavicon(_ url: URL?, _ item: NSMenuItem) {
        // 1. Create proper URL
        if let url = url {
            // 2. Configure proper size
            let processor = ResizingImageProcessor(referenceSize: CGSize(width: 16, height: 16))
            
            // 3. Use proper Kingfisher options
            let options: KingfisherOptionsInfo = [
                .processor(processor),
                .scaleFactor(NSScreen.main?.backingScaleFactor ?? 2),
                .cacheOriginalImage
            ]
            
            // 4. Set image with completion handler to ensure it's set
            item.kf.setImage(
                with: url,
                options: options
            ) { result in
                switch result {
                case .success(let value):
                    item.image = value.image
                case .failure(let error):
                    print("Error loading favicon: \(error)")
                    // Set fallback image
                    item.image = NSImage(systemSymbolName: "globe", accessibilityDescription: nil)
                }
            }
        } else {
            // Set default folder icon for directories
            item.image = NSImage(systemSymbolName: "folder.fill", accessibilityDescription: nil)
        }
    }
}
