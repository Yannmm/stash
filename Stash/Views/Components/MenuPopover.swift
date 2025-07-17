//
//  MenuPopover.swift
//  Stash
//
//  Created by Assistant on 2025/7/15.
//

import SwiftUI
import AppKit

// MARK: - Menu Popover Manager
class MenuPopoverManager: ObservableObject {
    private var popover: NSPopover?
    
    func showMenu(from statusButton: NSStatusBarButton, items: [MenuItemData]) {
        hideMenu()
        
        let contentView = CustomMenuView(items: items)
        let hostingController = NSHostingController(rootView: contentView)
        
        popover = NSPopover()
        popover?.contentViewController = hostingController
        popover?.behavior = .transient
        popover?.animates = true
        popover?.contentSize = CGSize(width: 250, height: 400) // Will auto-size
        
        // Position the popover
        let buttonFrame = statusButton.frame
        let preferredEdge: NSRectEdge = .minY
        
        popover?.show(relativeTo: buttonFrame, of: statusButton, preferredEdge: preferredEdge)
    }
    
    func hideMenu() {
        popover?.performClose(nil)
        popover = nil
    }
    
    var isMenuVisible: Bool {
        popover?.isShown ?? false
    }
}

// MARK: - Menu Builder Extension for Current App
extension AppDelegate {
    func buildCustomMenuItems(from entries: [any Entry], history: [(any Entry, String)], collapseHistory: Bool, searching: Bool) -> [MenuItemData] {
        var items: [MenuItemData] = []
        
        // Add search if searching
        if searching {
            items.append(searchMenuItem())
        } else {
            // Add history section
            if !history.isEmpty {
                items.append(historyMenuItem(history: history, collapseHistory: collapseHistory))
                items.append(.separator)
            }
        }
        
        // Add entries
        items.append(contentsOf: buildMenuItems(from: entries))
        
        // Add actions (only if not searching)
        if !searching {
            if !entries.isEmpty {
                items.append(.separator)
                items.append(MenuItemData(
                    title: "Welcome to Stashy 🎉",
                    isEnabled: false
                ))
            }
            
            items.append(contentsOf: [
                MenuItemData(
                    title: "Create New Bookmark",
                    icon: NSImage(systemSymbolName: "link.badge.plus", accessibilityDescription: nil),
                    keyEquivalent: "C",
//                    action: { [weak self] in self?.createBookmark() }
                ),
                MenuItemData(
                    title: "Import from File",
                    icon: NSImage(systemSymbolName: "square.and.arrow.down", accessibilityDescription: nil),
                    keyEquivalent: "I",
//                    action: { [weak self] in self?.importFromBrowsers() }
                ),
                .separator,
                MenuItemData(
                    title: "Search",
                    icon: NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: nil),
                    action: { [weak self] in self?.search() }
                ),
                MenuItemData(
                    title: "Manage",
                    icon: NSImage(systemSymbolName: "slider.horizontal.3", accessibilityDescription: nil),
                    keyEquivalent: "M",
                    action: { [weak self] in self?.edit() }
                ),
                MenuItemData(
                    title: "Settings",
                    icon: NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil),
                    keyEquivalent: "S",
                    action: { [weak self] in self?.openSettings() }
                ),
                MenuItemData(
                    title: "Quit",
                    icon: NSImage(systemSymbolName: "power", accessibilityDescription: nil),
                    action: { [weak self] in self?.quit() }
                )
            ])
        }
        
        return items
    }
    
    private func searchMenuItem() -> MenuItemData {
        return MenuItemData(
            title: "Search Results",
            icon: NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: nil),
            submenu: [
                MenuItemData(
                    title: "No results found",
                    isEnabled: false
                )
            ]
        )
    }
    
    private func historyMenuItem(history: [(any Entry, String)], collapseHistory: Bool) -> MenuItemData {
        let historyItems = history.map { (entry, keyEquivalent) in
            MenuItemData(
                title: entry.name,
                detail: getMenuItemDetail(for: entry),
                icon: getMenuItemIcon(for: entry),
                keyEquivalent: keyEquivalent,
                action: { [weak self] in
                    self?.performEntryAction(entry)
                }
            )
        }
        
        if collapseHistory {
            return MenuItemData(
                title: "Recently Visited",
                icon: NSImage(systemSymbolName: "clock.fill", accessibilityDescription: nil),
                submenu: historyItems
            )
        } else {
            // Return a container that represents the flat history items
            // Since we can't return multiple items, we'll create a disabled header
            return MenuItemData(
                title: "Recently Visited",
                icon: NSImage(systemSymbolName: "clock.fill", accessibilityDescription: nil),
                isEnabled: false
            )
        }
    }
    
    private func buildMenuItems(from entries: [any Entry], parentId: UUID? = nil) -> [MenuItemData] {
        let filteredEntries = entries.filter { $0.parentId == parentId }
        
        return filteredEntries.map { entry in
            let children = entry.children(among: entries)
            let submenu = children.isEmpty ? nil : buildMenuItems(from: entries, parentId: entry.id)
            
            return MenuItemData(
                title: entry.name,
                detail: getMenuItemDetail(for: entry),
                icon: getMenuItemIcon(for: entry),
                action: submenu == nil ? { [weak self] in self?.performEntryAction(entry) } : nil,
                submenu: submenu
            )
        }
    }
    
    private func getMenuItemDetail(for entry: any Entry) -> String? {
        switch entry {
        case let bookmark as Bookmark:
            return bookmark.url.absoluteString
        case let group as Group:
            let childCount = cabinet.storedEntries.filter { $0.parentId == group.id }.count
            return "\(childCount) item(s)"
        default:
            return nil
        }
    }
    
    private func getMenuItemIcon(for entry: any Entry) -> NSImage? {
        switch entry.icon {
        case .system(let name):
            let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)
            image?.isTemplate = true
            return image
        case .favicon(_):
            // For now, return a default web icon - you could implement favicon loading here
            return NSImage(systemSymbolName: "globe", accessibilityDescription: nil)
        case .local(let url):
            return NSWorkspace.shared.icon(forFile: url.path)
        }
    }
    
    private func performEntryAction(_ entry: any Entry) {
        if let bookmark = entry as? Bookmark {
            do {
                try cabinet.asRecent(bookmark)
            } catch {
                ErrorTracker.shared.add(error)
            }
        }
        (entry as? Actionable)?.open()
    }
}

// MARK: - Integration Helper
extension AppDelegate {
    private var menuPopoverManager: MenuPopoverManager {
        // Store as a static property or create a proper instance variable
        struct Static {
            static let manager = MenuPopoverManager()
        }
        return Static.manager
    }
    
    func showCustomMenu() {
        guard let statusButton = statusItem?.button,
              let menuData = menuSink.value else { return }
        
        let items = buildCustomMenuItems(
            from: menuData.0,
            history: menuData.1.map { ($0.0, $0.1) },
            collapseHistory: menuData.2,
            searching: menuData.3
        )
        
        menuPopoverManager.showMenu(from: statusButton, items: items)
    }
    
    func hideCustomMenu() {
        menuPopoverManager.hideMenu()
    }
} 
