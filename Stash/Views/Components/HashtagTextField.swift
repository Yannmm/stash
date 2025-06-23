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
        
        init(_ parent: HashtagTextField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            
            let text = textField.stringValue
            if let range = text.range(of: #"(?<=\s)#\w*$"#, options: .regularExpression) {
                print("Matched:", text[range])
                // Show suggestions menu
                showSuggestions(textField)
            }
            // Note: NSMenu closes automatically when user clicks elsewhere
            
            parent.text = textField.stringValue
        }
        
        func controlTextDidEndEditing(_ obj: Notification) {
            parent.onCommit()
        }
        
        func showSuggestions(_ textField: NSTextField) {
            guard
                let fieldEditor = textField.window?.fieldEditor(false, for: textField) as? NSTextView else { return }
            
            let selectedRange = fieldEditor.selectedRange()
            let cursorRect = fieldEditor.firstRect(forCharacterRange: selectedRange, actualRange: nil)
            
            // Create suggestion menu
            let menu = NSMenu()
            menu.addItem(withTitle: "#work", action: #selector(insertHashtag(_:)), keyEquivalent: "")
            menu.addItem(withTitle: "#personal", action: #selector(insertHashtag(_:)), keyEquivalent: "")
            menu.addItem(withTitle: "#project", action: #selector(insertHashtag(_:)), keyEquivalent: "")
            menu.addItem(withTitle: "#urgent", action: #selector(insertHashtag(_:)), keyEquivalent: "")
            
            // Set target for menu items
            for item in menu.items {
                item.target = self
            }
            
            // Show menu at cursor position
            menu.popUp(positioning: nil, at: NSPoint(x: cursorRect.origin.x, y: cursorRect.origin.y + cursorRect.height), in: nil)
        }
        
        @objc func insertHashtag(_ sender: NSMenuItem) {
            // Insert the selected hashtag into the text
            let hashtag = sender.title
            // You can implement the insertion logic here
            print("Selected hashtag: \(hashtag)")
        }
        

    }
}

extension HashtagTextField {
    func font(_ font: NSFont) -> HashtagTextField {
        var copy = self
        copy.font = font
        return copy
    }
}
