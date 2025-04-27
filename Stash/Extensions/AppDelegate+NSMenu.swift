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
    
    func generateMenu(from entries: [any Entry], history: [(any Entry, String)], collapseHistory: Bool) -> NSMenu {
        let menu = NSMenu()
        
        if !history.isEmpty {
            if collapseHistory {
                let item = NSMenuItem(title: "Recently Visited", action: nil, keyEquivalent: "")
                let image = NSImage(systemSymbolName: "clock.fill", accessibilityDescription: nil)
                image?.isTemplate = true
                item.image = image?.tint(color: Color.primary)
                let submenu = NSMenu()
                g(menu: submenu, entries: history.map({ $0.0 }), parentId: nil, keyEquivalents: history.map({ $0.1 }))
                item.submenu = submenu
                menu.addItem(item)
            } else {
                let item = NSMenuItem(title: "Recently Visited", action: nil, keyEquivalent: "")
                item.isEnabled = false
                menu.addItem(item)
                g(menu: menu, entries: history.map({ $0.0 }), parentId: nil, keyEquivalents: history.map({ $0.1 }))
            }
            menu.addItem(NSMenuItem.separator())
        }
        
        g(menu: menu, entries: entries, parentId: nil, keyEquivalents: [])
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Edit", action: #selector(togglePopover), keyEquivalent: "E"))
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: "S"))
        
        return menu
    }

    
    // TODO: shortcut
    private func g(menu: NSMenu, entries: [any Entry], parentId: UUID?, keyEquivalents: [String]) {
        menu.delegate = self

        for (index, entry) in entries.filter({ $0.parentId == parentId }).enumerated() {
            let actionable = entry is Actionable
            let item = CustomMenuItem(title: entry.name, action: actionable ? #selector(action(_:)) : nil, keyEquivalent: "", with: entry)
            if actionable {
                item.keyEquivalentModifierMask = []
                if index <= keyEquivalents.count - 1 {
                    item.keyEquivalent = keyEquivalents[index]
                }
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
                let submenu = NSMenu()
                g(menu: submenu, entries: entries, parentId: entry.id, keyEquivalents: keyEquivalents)
                item.submenu = submenu
            }
            menu.addItem(item)
        }
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
        if let b = sender.object as? Bookmark {
            // TODO: handle error
            try? cabinet.asRecent(b)
        }
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


var leftyKeystrokes: [String] {
    [
        "1", "2", "3", "4", "5",
        "q", "w", "e", "r", "t",
        "a", "s", "d", "f", "g",
        "z", "x", "c", "v", "b",
    ]
}
