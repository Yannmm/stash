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
        
        addHistory(menu, history, collapseHistory)
        
        addEntries(menu, entries)
        
        addGuide(menu, entries)
        
        addActions(menu)
        
        return menu
    }
    
    private func addHistory(_ menu: NSMenu, _ history: [(any Entry, String)], _ collapseHistory: Bool ) {
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
    }
    
    private func addGuide(_ menu: NSMenu, _ entries: [any Entry]) {
        var items = [
            NSMenuItem(title: "Welcom to Stashy 🎉", action: nil, keyEquivalent: ""),
            NSMenuItem(title: "Create New Bookmark", action: #selector(createBookmark), keyEquivalent: "C"),
            NSMenuItem(title: "Import from File", action: #selector(importFromBrowsers), keyEquivalent: "I")
        ] as [NSMenuItem]
        
        if entries.count > 0 {
            items.insert(NSMenuItem.separator(), at: 0)
        }
        
        items.forEach { menu.addItem($0) }
    }
    
    private func addActions(_ menu: NSMenu) {
//        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Manage", action: #selector(edit), keyEquivalent: "M"))
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: "S"))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: ""))
    }
    
    private func addEntries(_ menu: NSMenu, _ entries: [any Entry]) {
        g(menu: menu, entries: entries, parentId: nil, keyEquivalents: [])
    }

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
    
    private func setFavicon(_ url: URL, _ item: NSMenuItem) {
        let options: KingfisherOptionsInfo = [
            .processor(EmptyFaviconReplacer(url: url) |>
                       ResizingImageProcessor(referenceSize: CGSize(width: NSImage.Constant.side1, height: NSImage.Constant.side1), mode: .aspectFit)),
            .scaleFactor(NSScreen.main?.backingScaleFactor ?? 2),
            .cacheOriginalImage,
            .onFailureImage({
                let image = NSImage.drawFavicon(from: url.firstDomainLetter)
                image.size = CGSize(width: NSImage.Constant.side1, height: NSImage.Constant.side1)
                return image
            }())
        ]
        
        // 4. Set image with completion handler to ensure it's set
        item.kf.setImage(
            with: url,
            options: options
        )
    }
    
    @objc private func action(_ sender: CustomMenuItem) {
        if let b = sender.object as? Bookmark {
            do {
                try cabinet.asRecent(b)
            } catch {
                ErrorTracker.shared.add(error)
            }
            
        }
        (sender.object as? Actionable)?.open()
    }
    
    @objc private func createBookmark() {
        edit()
        DispatchQueue.main.asyncAfter(deadline: (DispatchTime.now() + 0.25)) {
            NotificationCenter.default.post(name: .onShouldPresentBookmarkForm, object: nil)
        }
    }
    
    @objc private func importFromBrowsers() {
        openSettings()
        DispatchQueue.main.asyncAfter(deadline: (DispatchTime.now() + 0.25)) {
            NotificationCenter.default.post(name: .onShouldOpenImportPanel, object: nil)
        }
    }
}

extension AppDelegate: NSMenuDelegate {
//    func menuNeedsUpdate(_ menu: NSMenu) {
//        let modifierFlags = NSEvent.modifierFlags
//        
//        for item in menu.items {
//            if modifierFlags.contains(.option) {
//                //                item.title = "Alternative Action"
//                print("ooooptions")
//            } else {
//                //                item.title = "Default Action"
//                print("default, no option")
//            }
//        }
//    }
}


var leftyKeystrokes: [String] {
    [
        "1", "2", "3", "4", "5",
        "q", "w", "e", "r", "t",
        "a", "s", "d", "f", "g",
        "z", "x", "c", "v", "b",
    ]
}
