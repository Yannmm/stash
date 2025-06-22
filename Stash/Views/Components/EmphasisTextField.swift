//
//  EmphasisTextField.swift
//  Stash
//
//  Created by Rayman on 2025/6/18.
//

import SwiftUI

struct EmphasisTextField: NSViewRepresentable {
    @Binding var text: String
    
    var font: NSFont?
    
    var onCommit: () -> Void = {}
    
    internal class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: EmphasisTextField
        
        init(_ parent: EmphasisTextField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            parent.text = textField.stringValue
        }
        
        func controlTextDidEndEditing(_ obj: Notification) {
            parent.onCommit()
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
}

extension EmphasisTextField {
    func font(_ font: NSFont) -> EmphasisTextField {
        var copy = self
        copy.font = font
        return copy
    }
}
