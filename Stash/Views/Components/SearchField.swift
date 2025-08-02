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
    let focused: Bool
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
        textField.font = font
        textField.lineBreakMode = .byTruncatingMiddle
        textField.usesSingleLineMode = true
        textField.focusRingType = .none
        textField.attributedStringValue = text.highlightHashtags()
        return textField
    }
    
    func updateNSView(_ textField: NSTextField, context: Context) {
        guard textField.stringValue != text else { return }
        textField.stringValue = text
        textField.font = font
        
        //        context.coordinator.monitorCursor(focused, textField)
        //
        //        if let coordinator = textField.delegate as? Coordinator, !focused {
        //            coordinator.hide()
        //        }
        
        //        guard textField.window?.firstResponder != textField.currentEditor() else {
        //            // Already focused; do nothing.
        //            return
        //        }
        
        //        textField.attributedStringValue = text.highlightHashtags()
        //
        //        // Move cursor to end if it just became first responder
        //        DispatchQueue.main.async {
        //            if let editor = textField.currentEditor() {
        //                let range = NSRange(location: (editor.string as NSString).length, length: 0)
        //                editor.selectedRange = range
        //                editor.scrollRangeToVisible(range)
        //            }
        //        }
        
        //        DispatchQueue.main.async {
        //            let _ = focused ? textField.becomeFirstResponder() : textField.resignFirstResponder()
        //        }
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
        
        func controlTextDidEndEditing(_ obj: Notification) {
            //            parent.onCommit()
        }
        
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
