//
//  AppDelegate+Search.swift
//  Stash
//
//  Created by Yan Meng on 2025/7/13.
//

import AppKit
import SwiftUI

extension AppDelegate {
    @objc func search() {
        searchViewModel.searching = true
            
        DispatchQueue.main.async { [weak self] in
            if let button = self?.statusItem?.button {
                button.performClick(nil)
            }
        }
    }
    
    func addSearch(_ menu: NSMenu) {
        let searchField = NSSearchField()
        searchField.placeholderString = "Search"
        searchField.font = NSFont.systemFont(ofSize: 13)
        searchField.focusRingType = .none
        searchField.bezelStyle = .roundedBezel
        searchField.cell?.isScrollable = true
        searchField.cell?.sendsActionOnEndEditing = true
        
        // Make search field unfocused initially
        searchField.refusesFirstResponder = false
        
        // Configure search field behavior
        searchField.target = self
        searchField.action = #selector(searchFieldAction(_:))
        
        // Configure search button and cancel button
//        if let searchButtonCell = searchField.cell?.searchButtonCell {
//            searchButtonCell.target = self
//            searchButtonCell.action = #selector(searchButtonClicked(_:))
//        }
//
//        if let cancelButtonCell = searchField.cell?.cancelButtonCell {
//            cancelButtonCell.target = self
//            cancelButtonCell.action = #selector(searchCancelClicked(_:))
//        }
        
        // Create container view with padding
        let containerView = NSView()
        containerView.frame = CGRect(x: 0, y: 0, width: 240, height: 30)
        containerView.addSubview(searchField)
        
        // Center the search field in the container with padding
        searchField.frame = CGRect(x: 10, y: 4, width: 220, height: 22)
        
        // Ensure container doesn't automatically focus the search field
        
        let searchMenuItem = NSMenuItem(title: "Search", action: nil, keyEquivalent: "")
        searchMenuItem.view = containerView
        
        // Ensure menu item doesn't automatically focus its view
        searchMenuItem.isEnabled = true
        
        
        
        // Delay to ensure search field doesn't auto-focus when menu opens
//        DispatchQueue.main.async {
//            searchField.resignFirstResponder()
//        }
        
        menu.addItem(searchMenuItem)
    }
    
    @objc private func searchFieldAction(_ sender: NSSearchField) {
        let searchText = sender.stringValue
        print("Search action: \(searchText)")
        // TODO: Implement search functionality
        performSearch(searchText)
    }
    
    @objc private func searchButtonClicked(_ sender: Any) {
        if let searchField = sender as? NSSearchFieldCell {
            let searchText = searchField.stringValue
            print("Search button clicked: \(searchText)")
            performSearch(searchText)
        }
    }
    
    @objc private func searchCancelClicked(_ sender: Any) {
        print("Search cancelled")
        // Clear search results or reset state
    }
    
    private func performSearch(_ searchText: String) {
        guard !searchText.isEmpty else { return }
        
        // Filter entries based on search text
        let filteredEntries = cabinet.storedEntries.filter { entry in
            entry.name.localizedCaseInsensitiveContains(searchText)
        }
        
        print("Found \(filteredEntries.count) results for: \(searchText)")
        // TODO: Update UI to show search results
    }
}
