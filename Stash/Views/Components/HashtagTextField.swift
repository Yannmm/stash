//
//  EmphasisTextField.swift
//  Stash
//
//  Created by Rayman on 2025/6/18.
//

import SwiftUI

struct HashtagTextField: NSViewRepresentable {
    @Binding var text: String
    var font: NSFont?
    var onCommit: () -> Void = {}
    
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
                let range = NSRange(location: (editor.string as NSString).length, length: 0)
                editor.selectedRange = range
                editor.scrollRangeToVisible(range)
            }
        }
    }
    
    internal class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: HashtagTextField
        weak var currentTextField: NSTextField?
        var suggestionsPanel: NSPanel?
        
        init(_ parent: HashtagTextField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            
            let text = textField.stringValue
            print("Text changed to: '\(text)'")
            
            // Updated regex to allow hashtag at beginning or after whitespace
            if let range = text.range(of: #"(^|(?<=\s))#\w*$"#, options: .regularExpression) {
                print("Matched hashtag pattern: '\(text[range])'")
                // Show suggestions window
                showSuggestions(textField)
            } else {
                print("No hashtag pattern found")
                // Hide suggestions when no hashtag pattern
                hideSuggestions()
            }
            
            parent.text = textField.stringValue
        }
        
        func controlTextDidEndEditing(_ obj: Notification) {
            parent.onCommit()
        }
        
                func showSuggestions(_ textField: NSTextField) {
            print("showSuggestions called")
            guard
                let fieldEditor = textField.window?.fieldEditor(false, for: textField) as? NSTextView else { 
                print("Failed to get field editor")
                return 
            }
            
            let selectedRange = fieldEditor.selectedRange()
            let cursorRect = fieldEditor.firstRect(forCharacterRange: selectedRange, actualRange: nil)
            print("Cursor rect: \(cursorRect)")
            
            // Store reference to text field
            currentTextField = textField
            
            // Create or update suggestion window
            createSuggestionWindow(at: cursorRect)
        }
        
        func createSuggestionWindow(at cursorRect: NSRect) {
            print("createSuggestionWindow called with cursorRect: \(cursorRect)")
            
            // Close existing panel if any
            suggestionsPanel?.close()
            
            // Create suggestions
            let suggestions = ["#work", "#personal", "#project", "#urgent"]
            
            // Calculate panel size
            let panelWidth: CGFloat = 120
            let itemHeight: CGFloat = 22
            let panelHeight = CGFloat(suggestions.count) * itemHeight
            
            // Position panel below cursor
            let panelRect = NSRect(
                x: cursorRect.origin.x,
                y: cursorRect.origin.y - panelHeight,
                width: panelWidth,
                height: panelHeight
            )
            
            print("Panel rect: \(panelRect)")
            
            // Create panel that doesn't steal focus
            let panel = NSPanel(
                contentRect: panelRect,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            
            panel.level = .popUpMenu
            panel.isOpaque = true
            panel.backgroundColor = NSColor.controlBackgroundColor
            panel.hasShadow = true
            panel.worksWhenModal = true
            panel.becomesKeyOnlyIfNeeded = false
            panel.acceptsMouseMovedEvents = true
            
            // Create content view
            let contentView = SuggestionListView(suggestions: suggestions, coordinator: self)
            
            panel.contentView = contentView
            panel.orderFront(nil)
            
            print("Panel created and ordered front")
            
            suggestionsPanel = panel
        }
        
        func hideSuggestions() {
//            print("Hiding suggestions panel")
            suggestionsPanel?.close()
//            suggestionsPanel = nil
//            print("Suggestions panel closed and cleared")
        }
        
        func insertHashtag(_ hashtag: String) {
            print("🔸 Inserting hashtag: '\(hashtag)'")
            guard let textField = currentTextField else { 
                print("❌ No current text field available")
                return 
            }
            
            // Replace the partial hashtag with the selected one
            let text = textField.stringValue
            print("🔸 Current text: '\(text)'")
            
            // Use the same regex pattern as in controlTextDidChange
            if let range = text.range(of: #"(^|(?<=\s))#\w*$"#, options: .regularExpression) {
                let newText = text.replacingCharacters(in: range, with: hashtag)
                textField.stringValue = newText
                parent.text = newText
                print("✅ Updated text to: '\(newText)'")
                
                // Move cursor to end of inserted hashtag
                if let editor = textField.currentEditor() {
                    let newPosition = newText.count
                    editor.selectedRange = NSRange(location: newPosition, length: 0)
                    print("✅ Moved cursor to position: \(newPosition)")
                }
            } else {
                print("❌ No hashtag pattern found to replace")
            }
            
            print("✅ Text field remains focused and active - only closing suggestion panel")
        }
        

    }
}

class SuggestionListView: NSView {
    private let suggestions: [String]
    private weak var coordinator: HashtagTextField.Coordinator?
    
    init(suggestions: [String], coordinator: HashtagTextField.Coordinator) {
        self.suggestions = suggestions
        self.coordinator = coordinator
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        layer?.cornerRadius = 6
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.separatorColor.cgColor
        
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.spacing = 1
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        for (index, suggestion) in suggestions.enumerated() {
            let button = NSButton()
            button.title = suggestion
            button.target = self
            button.action = #selector(suggestionSelected(_:))
            button.bezelStyle = .texturedRounded
            button.isBordered = true
            button.alignment = .left
            button.tag = index
            
            // Configure button for proper mouse interaction
            button.isEnabled = true
            button.allowsMixedState = false
            
            // Set explicit height
            button.heightAnchor.constraint(equalToConstant: 22).isActive = true
            
            // Make sure button can receive mouse events
            button.translatesAutoresizingMaskIntoConstraints = false
            
            // Debug button setup
            print("Created button: '\(suggestion)' with target: \(String(describing: button.target)) action: \(String(describing: button.action))")
            
            stackView.addArrangedSubview(button)
        }
        
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])
        
        print("SuggestionListView setup completed with \(suggestions.count) suggestions")
    }
    
    @objc private func suggestionSelected(_ sender: NSButton) {
        print("suggestionSelected called with button tag: \(sender.tag)")
        guard let coordinator = coordinator else { 
            print("No coordinator available")
            return 
        }
        let suggestion = suggestions[sender.tag]
        print("Selected suggestion: \(suggestion)")
        coordinator.insertHashtag(suggestion)
        coordinator.hideSuggestions()
    }
}

extension HashtagTextField {
    func font(_ font: NSFont) -> HashtagTextField {
        var copy = self
        copy.font = font
        return copy
    }
}
