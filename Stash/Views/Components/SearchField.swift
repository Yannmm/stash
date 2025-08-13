//
//  PseudoTextField.swift
//  Stash
//
//  Created by Yan Meng on 2025/8/1.
//

import SwiftUI
import AppKit
import Combine

struct SearchField: NSViewRepresentable {
    @Environment(\.colorScheme) var colorScheme
    @Binding var text: String
    @Binding var keyboardAction: KeyboardAction?
    @Binding var focused: Bool
    var font: NSFont?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.stringValue = text
        textField.delegate = context.coordinator
        textField.isEditable = true
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.font = font
        textField.lineBreakMode = .byTruncatingMiddle
        textField.usesSingleLineMode = true
        textField.focusRingType = .none
        textField.setContentHuggingPriority(.defaultHigh, for: .vertical)
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.heightAnchor.constraint(equalToConstant: 22)
        ])
        return textField
    }
    
    func updateNSView(_ textField: NSTextField, context: Context) {
        if text != textField.stringValue {
            textField.stringValue = text
        }
        
        textField.font = font
        
        // Handle focus state
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            let isFocus = textField.window?.firstResponder == textField.currentEditor()
            let flag = focused && !isFocus
            if flag {
                let _ = textField.becomeFirstResponder()
            } else {
                let _ = textField.resignFirstResponder()
            }
        }
    }
    
    internal class Coordinator: NSObject, NSTextFieldDelegate {
        private var parent: SearchField
        
        init(_ parent: SearchField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            parent.text = textField.stringValue
        }
        
        func controlTextDidEndEditing(_ obj: Notification) {}
        
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            switch commandSelector {
            case #selector(NSResponder.moveDown(_:)):
                parent.keyboardAction = .down
                return true
            case #selector(NSResponder.moveUp(_:)):
                parent.keyboardAction = .up
                return true
            case #selector(NSResponder.insertNewline(_:)):
                parent.keyboardAction = .enter
                return true
            default:
                return false
            }
        }
    }
}

extension SearchField {
    func font(_ font: NSFont) -> Self {
        var copy = self
        copy.font = font
        return copy
    }
}
