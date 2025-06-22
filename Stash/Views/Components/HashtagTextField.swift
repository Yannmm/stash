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
                // Show popover
                showSuggestions(textField)
            } else {
                popover.performClose(nil)
            }
            
            parent.text = textField.stringValue
        }
        
        func controlTextDidEndEditing(_ obj: Notification) {
            parent.onCommit()
        }
        
        func showSuggestions(_ textField: NSTextField) {
            guard
                let fieldEditor = textField.window?.fieldEditor(false, for: textField) as? NSTextView else { return }
            
            let selectedRange = fieldEditor.selectedRange()
            let rect = fieldEditor.firstRect(forCharacterRange: selectedRange, actualRange: nil)
            let localRect = fieldEditor.convert(rect, to: nil) // convert to window coords
            popover.show(relativeTo: rect, of: textField, preferredEdge: .minY)
        }
        
        private lazy var popover: NSPopover = {
            // Setup the popover
            let popover = NSPopover()
                    let hintViewController = NSViewController()
                    hintViewController.view = NSView(frame: NSRect(x: 0, y: 0, width: 150, height: 50))
                    hintViewController.view.wantsLayer = true
                    hintViewController.view.layer?.backgroundColor = NSColor.systemYellow.cgColor

                    popover.contentViewController = hintViewController
                    popover.behavior = .semitransient // or .transient
            
            return popover
        }()
    }
}

extension HashtagTextField {
    func font(_ font: NSFont) -> HashtagTextField {
        var copy = self
        copy.font = font
        return copy
    }
}
