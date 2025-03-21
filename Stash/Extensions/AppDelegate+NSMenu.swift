//
//  AppDelegate+NSMenu.swift
//  Stash
//
//  Created by Rayman on 2025/2/10.
//

import AppKit
import SwiftUI
import Kingfisher

@MainActor
extension AppDelegate {
    
    func generateMenu(from entries: [any Entry]) -> NSMenu {
        let menu = g(entries: entries, parentId: nil)
        
        return appendMore(menu: menu)
    }
    
    private func appendMore(menu: NSMenu) -> NSMenu {
        // Append drag & drop
        menu.addItem(NSMenuItem.separator())
        let item1 = NSMenuItem(title: "Drag & Drop", action: #selector(togglePopover), keyEquivalent: "G")
        menu.addItem(item1)
        
        // Clear all
        let item2 = NSMenuItem(title: "Clear All", action: #selector(deleteAll), keyEquivalent: "A")
        menu.addItem(item2)
        
        return menu
    }
    
    private func g(entries: [any Entry], parentId: UUID?, isRoot: Bool = true) -> NSMenu {
        let menu = NSMenu()
        
        
        entries.filter({ $0.parentId == parentId }).forEach { e in
            let item = CustomMenuItem(title: e.name, action: #selector(action(_:)), keyEquivalent: "", with: e)
            
            switch e.icon {
            case Icon.system(let name):
                let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)
                image?.isTemplate = true
                item.image = image?.tint(color: Color.primary)
            case Icon.favicon(let url):
                setFavicon(url, item)
            }
            
            let children = e.children(among: entries)
            if !children.isEmpty {
                let submenu = g(entries: children, parentId: e.id, isRoot: false)
                item.submenu = submenu
            }
            menu.addItem(item)
        }
        return menu
    }
    
    private func setFavicon(_ url: URL?, _ item: NSMenuItem) {
        // 1. Create proper URL
        if let url = url {
            // 2. Configure proper size
//            let processor = ResizingImageProcessor(referenceSize: CGSize(width: 32, height: 32), mode: .aspectFit)
            
            // 3. Use proper Kingfisher options
            let options: KingfisherOptionsInfo = [
//                .processor(processor),
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
                    item.image?.size = CGSize(width: 16, height: 16)
                case .failure(let error):
                    print("Error loading favicon: \(error)")
                    // Set fallback image
                    item.image = NSImage(systemSymbolName: "globe", accessibilityDescription: nil)
                }
            }
        } else {
            // Set default folder icon for directories
            item.image = NSImage(systemSymbolName: "globe", accessibilityDescription: nil)
        }
    }
    
    @objc private func action(_ sender: CustomMenuItem) {
        sender.object?.open()
    }
}
