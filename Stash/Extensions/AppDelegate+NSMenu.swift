//
//  AppDelegate+NSMenu.swift
//  Stash
//
//  Created by Rayman on 2025/2/10.
//

import AppKit
import SwiftUI

extension AppDelegate {
    func generateMenu(from entries: [Entry]) -> NSMenu {
//        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
//        let contentView = ContentView().environmentObject(BookmarkManager.shared)
//        popover.contentSize = NSSize(width: 300, height: 400)
//        popover.behavior = .transient
//        popover.contentViewController = NSHostingController(rootView: contentView)
        
//        if let button = statusItem.button {
//            button.image = NSImage(systemSymbolName: "bookmark.fill", accessibilityDescription: nil)
////            button.action = #selector(togglePopover)
//        }
        
//        let xxx = entries.map { entry in
//            <#code#>
//        }
//        
//        let menu = NSMenu()
//        
//        let k1 = NSMenuItem(title: "", action: nil, keyEquivalent: "")
//        let text = "History"
//        let attributedString = NSMutableAttributedString(string: "History")
//
//        // Define the attributes you want to apply
//        let boldAttributes: [NSAttributedString.Key: Any] = [
//            .font: NSFont.boldSystemFont(ofSize: 14),
//            .foregroundColor: NSColor.red
//        ]
//        
//        attributedString.addAttributes(boldAttributes, range: (text as NSString).range(of: "Hello"))
//        k1.attributedTitle = attributedString
//        menu.addItem(k1)
//        
//        let p = NSMenuItem(title: "Open Settings", action: #selector(openSettings), keyEquivalent: "S")
//        let n = NSMenuItem(title: "Secondary Level", action: #selector(togglePopover), keyEquivalent: "P")
//        let n1 = NSMenu()
//        n1.addItem(n)
//        p.submenu = n1
//        menu.addItem(p)
//        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "Q"))
//        
//        statusItem.menu = menu
        
        let kkk1 = g(entries: entries)
        return kkk1
    }
    
    private func g(entries: [Entry], isRoot: Bool = true) -> NSMenu {
        let menu = NSMenu()
        entries.forEach { e in
            let item = CustomMenuItem(title: e.name, action: #selector(action(_:)), keyEquivalent: "", with: e)
            if !e.entries.isEmpty {
                let submenu = g(entries: e.entries, isRoot: false)
                item.submenu = submenu
            }
            menu.addItem(item)
        }
        return menu
    }
    
    @objc private func action(_ sender: CustomMenuItem) {
        sender.object?.open()
    }
}
