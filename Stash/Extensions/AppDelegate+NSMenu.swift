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
        return g(entries: entries)
    }
    
    private func g(entries: [Entry], isRoot: Bool = true) -> NSMenu {
        let menu = NSMenu()
        entries.forEach { e in
            let item = CustomMenuItem(title: e.name, action: #selector(action(_:)), keyEquivalent: "", with: e)
            var image = NSImage(contentsOf: URL(string: "https://a0.muscache.com/airbnb/static/icons/apple-touch-icon-76x76-3b313d93b1b5823293524b9764352ac9.png")!)
            
//            http://icons.duckduckgo.com/ip2/www.stackoverflow.com.ico
            //            http://icons.duckduckgo.com/ip2/www.baidu.com.ico
            //            http://icons.duckduckgo.com/ip2/stackedit.io.ico
            // https://stackoverflow.com/questions/5119041/how-can-i-get-a-web-sites-favicon
            // http://icons.duckduckgo.com/ip2/10.133.110.49:8080.ico
            
            image?.size = NSSize(width: 16, height: 16)
            image = image?.roundCorners(radius: 8)
            item.image = image
            if !e.entries.isEmpty {
                let submenu = g(entries: e.entries, isRoot: false)
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
}
