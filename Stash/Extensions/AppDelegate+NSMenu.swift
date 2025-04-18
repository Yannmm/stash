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
        let item1 = NSMenuItem(title: "Drag & Drop", action: #selector(togglePopover), keyEquivalent: "")
        item1.keyEquivalentModifierMask = .command
        item1.keyEquivalent = "D"
        menu.addItem(item1)
                
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ","))
        return menu
    }
    
    private func g(entries: [any Entry], parentId: UUID?) -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self
        var index = 1
        for entry in entries.filter({ $0.parentId == parentId }) {
            let actionable = entry is Actionable
            let item = CustomMenuItem(title: entry.name, action: actionable ? #selector(action(_:)) : nil, keyEquivalent: "", with: entry)
            if actionable {
                item.keyEquivalentModifierMask = []
                item.keyEquivalent = "\(index)"
                index += 1
            }
            
            switch entry.icon {
            case Icon.system(let name):
                let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)
                image?.isTemplate = true
                item.image = image?.tint(color: Color.primary)
            case Icon.favicon(let url):
                setFavicon(url, item)
            case Icon.local(let url):
                let i = NSWorkspace.shared.icon(forFile: url.path)
                i.size = NSImage.Constant.scaledSize1
                item.image = i
            }
            
            let children = entry.children(among: entries)
            if !children.isEmpty {
                let submenu = g(entries: children, parentId: entry.id)
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
                    item.image?.size = NSImage.Constant.size1
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
        (sender.object as? Actionable)?.open()
    }
}


extension AppDelegate: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        let modifierFlags = NSEvent.modifierFlags
        
        for item in menu.items {
            if modifierFlags.contains(.option) {
//                item.title = "Alternative Action"
                print("ooooptions")
            } else {
//                item.title = "Default Action"
                print("default, no option")
            }
        }
    }
}
