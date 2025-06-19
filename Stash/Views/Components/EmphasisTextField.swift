//
//  EmphasisTextField.swift
//  Stash
//
//  Created by Rayman on 2025/6/18.
//

import SwiftUI
import AppKit

struct EmphasisTextField: NSViewRepresentable {
    @Binding var text: String
    
    var font: NSFont?
    
    var onCommit: () -> Void = {}
    
    // Add support for hashtag suggestions
    var suggestions: [String] = []
    var onSuggestionSelected: ((String) -> Void)?
    
    // Custom initializer with suggestions
    init(text: Binding<String>, font: NSFont? = nil, onCommit: @escaping () -> Void = {}, suggestions: [String] = [], onSuggestionSelected: ((String) -> Void)? = nil) {
        self._text = text
        self.font = font
        self.onCommit = onCommit
        self.suggestions = suggestions
        self.onSuggestionSelected = onSuggestionSelected
    }
    
    internal class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: EmphasisTextField
        var suggestionPanel: NSPanel?
        var suggestionViewController: SuggestionViewController?
        var currentTextField: NSTextField?
        
        init(_ parent: EmphasisTextField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            parent.text = textField.stringValue
            currentTextField = textField
            
            // Check for hashtag trigger
            checkForHashtagTrigger(textField: textField)
        }
        
        func controlTextDidEndEditing(_ obj: Notification) {
            parent.onCommit()
            hideSuggestionPanel()
        }
        
        private func checkForHashtagTrigger(textField: NSTextField) {
            guard let editor = textField.currentEditor() else { 
                print("DEBUG: No editor available")
                return 
            }
            
            let currentText = editor.string
            let selectedRange = editor.selectedRange
            
            print("DEBUG: Current text: '\(currentText)', cursor position: \(selectedRange.location)")
            
            // Find the word being typed (from cursor position backwards)
            let beforeCursor = String(currentText.prefix(selectedRange.location))
            
            // Check if we're typing a hashtag
            if let hashtagRange = beforeCursor.range(of: "#[^\\s]*$", options: .regularExpression) {
                let hashtagStart = beforeCursor.distance(from: beforeCursor.startIndex, to: hashtagRange.lowerBound)
                let hashtagText = String(beforeCursor[hashtagRange])
                let query = String(hashtagText.dropFirst()) // Remove the # symbol
                
                print("DEBUG: Found hashtag: '\(hashtagText)', query: '\(query)', start: \(hashtagStart)")
                
                if !query.isEmpty {
                    showSuggestionPanel(textField: textField, query: query, hashtagStart: hashtagStart)
                } else {
                    hideSuggestionPanel()
                }
            } else {
                print("DEBUG: No hashtag pattern found")
                // Check if we just typed a space or other character that should close the panel
                if let lastChar = beforeCursor.last, lastChar.isWhitespace || lastChar == "#" {
                    hideSuggestionPanel()
                }
            }
        }
        
        private func showSuggestionPanel(textField: NSTextField, query: String, hashtagStart: Int) {
            // Filter suggestions based on query
            let filteredSuggestions = parent.suggestions.filter { suggestion in
                suggestion.lowercased().contains(query.lowercased())
            }
            
            guard !filteredSuggestions.isEmpty else {
                hideSuggestionPanel()
                return
            }
            
            print("DEBUG: Found \(filteredSuggestions.count) suggestions for query: \(query)")
            
            // Create or update suggestion view controller
            if suggestionViewController == nil {
                suggestionViewController = SuggestionViewController()
                suggestionViewController?.delegate = self
            }
            
            suggestionViewController?.suggestions = filteredSuggestions
            suggestionViewController?.query = query
            suggestionViewController?.hashtagStart = hashtagStart
            
            // Create or update panel
            if suggestionPanel == nil {
                suggestionPanel = createSuggestionPanel()
            }
            
            // Ensure the panel has the content view controller
            if suggestionPanel?.contentViewController == nil {
                suggestionPanel?.contentViewController = suggestionViewController
            }
            
            // Position panel below the text field
            if let panel = suggestionPanel, let window = textField.window {
                // Set the panel as a child window of the main window
                if panel.parent == nil {
                    window.addChildWindow(panel, ordered: .above)
                }
                
                let textFieldFrame = textField.convert(textField.bounds, to: nil)
                let windowFrame = window.convertPoint(toScreen: textFieldFrame.origin)
                
                // Calculate the position for the hashtag part of the text
                let hashtagX = windowFrame.x + CGFloat(hashtagStart) * 6
                let panelY = windowFrame.y - 120 // Position below the text field
                
                let panelFrame = NSRect(
                    x: hashtagX,
                    y: panelY,
                    width: 200,
                    height: min(CGFloat(filteredSuggestions.count * 32 + 20), 150)
                )
                
                print("DEBUG: Setting panel frame to: \(panelFrame)")
                panel.setFrame(panelFrame, display: true)
                
                if !panel.isVisible {
                    print("DEBUG: Making panel visible")
                    panel.makeKeyAndOrderFront(nil)
                }
            } else {
                print("DEBUG: Failed to get panel or window")
            }
        }
        
        private func createSuggestionPanel() -> NSPanel {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 200, height: 150),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            
            panel.isFloatingPanel = false
            panel.level = .normal
            panel.backgroundColor = NSColor.clear
            panel.isOpaque = false
            panel.hasShadow = true
            panel.ignoresMouseEvents = false
            panel.collectionBehavior = [.managed]
            
            print("DEBUG: Created suggestion panel")
            
            return panel
        }
        
        private func hideSuggestionPanel() {
            suggestionPanel?.orderOut(nil)
            suggestionPanel = nil
            suggestionViewController = nil
        }
        
        func insertSuggestion(_ suggestion: String, hashtagStart: Int) {
            guard let textField = currentTextField,
                  let editor = textField.currentEditor() else { return }
            
            let currentText = editor.string
            let selectedRange = editor.selectedRange
            
            // Calculate the range to replace
            let beforeCursor = String(currentText.prefix(selectedRange.location))
            
            // Find the hashtag range in the text before cursor
            guard let hashtagRange = beforeCursor.range(of: "#[^\\s]*$", options: .regularExpression) else { return }
            
            let hashtagStartIndex = beforeCursor.distance(from: beforeCursor.startIndex, to: hashtagRange.lowerBound)
            let hashtagEndIndex = beforeCursor.count
            
            // Create the replacement text
            let replacementText = "#\(suggestion) "
            
            // Replace the hashtag with the selected suggestion
            let newText = String(currentText.prefix(hashtagStartIndex)) + replacementText + String(currentText.suffix(from: currentText.index(currentText.startIndex, offsetBy: hashtagEndIndex)))
            
            // Update the text field
            textField.stringValue = newText
            parent.text = newText
            
            // Set cursor position after the inserted suggestion
            let newCursorPosition = hashtagStartIndex + replacementText.count
            editor.selectedRange = NSRange(location: newCursorPosition, length: 0)
            
            // Hide the panel
            hideSuggestionPanel()
            
            // Notify parent about the selection
            parent.onSuggestionSelected?(suggestion)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.delegate = context.coordinator
        textField.isEditable = true
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.focusRingType = .none
        textField.font = font
        textField.lineBreakMode = .byTruncatingMiddle
        textField.usesSingleLineMode = true
        textField.stringValue = text
        
        // Add a subtle placeholder hint about hashtag functionality
        if text.isEmpty {
            textField.placeholderString = "Type # for hashtag suggestions..."
        }
        
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        nsView.font = font
        guard nsView.window?.firstResponder != nsView.currentEditor() else {
            // Already focused; do nothing.
            return
        }
        nsView.stringValue = text
        
        // Move cursor to end if it just became first responder
        DispatchQueue.main.async {
            if let editor = nsView.currentEditor() {
                let range = NSRange(location: editor.string.count, length: 0)
                editor.selectedRange = range
                editor.scrollRangeToVisible(range)
            }
        }
    }
}

// MARK: - Suggestion View Controller
class SuggestionViewController: NSViewController {
    weak var delegate: EmphasisTextField.Coordinator?
    var suggestions: [String] = []
    var query: String = ""
    var hashtagStart: Int = 0
    
    private var tableView: NSTableView!
    private var scrollView: NSScrollView!
    private var containerView: NSView!
    
    override func loadView() {
        view = NSView()
        setupContainerView()
        setupTableView()
    }
    
    private func setupContainerView() {
        containerView = NSView()
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        containerView.layer?.cornerRadius = 8
        containerView.layer?.borderWidth = 1
        containerView.layer?.borderColor = NSColor.separatorColor.cgColor
        containerView.layer?.shadowColor = NSColor.black.cgColor
        containerView.layer?.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer?.shadowRadius = 8
        containerView.layer?.shadowOpacity = 0.15
        
        view.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupTableView() {
        // Create scroll view
        scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        
        // Create table view
        tableView = NSTableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.headerView = nil
        tableView.rowHeight = 32
        tableView.selectionHighlightStyle = .regular
        tableView.backgroundColor = NSColor.clear
        tableView.gridStyleMask = []
        tableView.intercellSpacing = NSSize(width: 0, height: 0)
        
        // Add column
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Suggestion"))
        column.width = 180
        tableView.addTableColumn(column)
        
        scrollView.documentView = tableView
        containerView.addSubview(scrollView)
        
        // Setup constraints
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 4),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 4),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -4),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -4)
        ])
        
        // Set view size
        view.frame = NSRect(x: 0, y: 0, width: 200, height: min(CGFloat(suggestions.count * 32 + 20), 150))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.reloadData()
        
        // Select first row
        if suggestions.count > 0 {
            tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        }
    }
    
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 125: // Down arrow
            let currentRow = tableView.selectedRow
            let nextRow = min(currentRow + 1, suggestions.count - 1)
            tableView.selectRowIndexes(IndexSet(integer: nextRow), byExtendingSelection: false)
            tableView.scrollRowToVisible(nextRow)
        case 126: // Up arrow
            let currentRow = tableView.selectedRow
            let prevRow = max(currentRow - 1, 0)
            tableView.selectRowIndexes(IndexSet(integer: prevRow), byExtendingSelection: false)
            tableView.scrollRowToVisible(prevRow)
        case 36: // Enter key
            let selectedRow = tableView.selectedRow
            if selectedRow >= 0 && selectedRow < suggestions.count {
                let suggestion = suggestions[selectedRow]
                delegate?.insertSuggestion(suggestion, hashtagStart: hashtagStart)
            }
        case 53: // Escape key
            // Close panel without selection
            view.window?.orderOut(nil)
        default:
            super.keyDown(with: event)
        }
    }
}

// MARK: - Table View Data Source & Delegate
extension SuggestionViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return suggestions.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let identifier = NSUserInterfaceItemIdentifier("SuggestionCell")
        var cell = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView
        
        if cell == nil {
            cell = NSTableCellView()
            cell?.identifier = identifier
            
            let textField = NSTextField()
            textField.isEditable = false
            textField.isBordered = false
            textField.backgroundColor = .clear
            textField.font = NSFont.systemFont(ofSize: 13)
            textField.textColor = NSColor.labelColor
            textField.translatesAutoresizingMaskIntoConstraints = false
            
            cell?.addSubview(textField)
            cell?.textField = textField
            
            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: cell!.leadingAnchor, constant: 12),
                textField.trailingAnchor.constraint(equalTo: cell!.trailingAnchor, constant: -12),
                textField.centerYAnchor.constraint(equalTo: cell!.centerYAnchor)
            ])
        }
        
        let suggestion = suggestions[row]
        cell?.textField?.stringValue = suggestion
        
        // Highlight the matching part of the suggestion
        if let textField = cell?.textField {
            let attributedString = NSMutableAttributedString(string: suggestion)
            if let range = suggestion.range(of: query, options: .caseInsensitive) {
                let nsRange = NSRange(range, in: suggestion)
                attributedString.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: 13), range: nsRange)
                attributedString.addAttribute(.foregroundColor, value: NSColor.controlAccentColor, range: nsRange)
            }
            textField.attributedStringValue = attributedString
        }
        
        return cell
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return true
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = tableView.selectedRow
        if selectedRow >= 0 && selectedRow < suggestions.count {
            let suggestion = suggestions[selectedRow]
            delegate?.insertSuggestion(suggestion, hashtagStart: hashtagStart)
        }
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let rowView = NSTableRowView()
        rowView.backgroundColor = NSColor.clear
        return rowView
    }
}

// MARK: - Coordinator Extension for Suggestion Handling
extension EmphasisTextField.Coordinator: SuggestionViewControllerDelegate {
    func suggestionViewController(_ controller: SuggestionViewController, didSelectSuggestion suggestion: String) {
        insertSuggestion(suggestion, hashtagStart: controller.hashtagStart)
    }
}

// MARK: - Suggestion View Controller Delegate Protocol
protocol SuggestionViewControllerDelegate: AnyObject {
    func suggestionViewController(_ controller: SuggestionViewController, didSelectSuggestion suggestion: String)
}

extension EmphasisTextField {
    func font(_ font: NSFont) -> EmphasisTextField {
        var copy = self
        copy.font = font
        return copy
    }
    
    func suggestions(_ suggestions: [String], onSuggestionSelected: @escaping (String) -> Void) -> EmphasisTextField {
        var copy = self
        copy.suggestions = suggestions
        copy.onSuggestionSelected = onSuggestionSelected
        return copy
    }
}
