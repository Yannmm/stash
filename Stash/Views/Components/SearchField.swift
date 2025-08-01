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
//    @EnvironmentObject var viewModel: HashtagViewModel
    @Binding var text: String
//    @State var suggestionIndex: Int?
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
        textField.font = font
        
//        context.coordinator.monitorCursor(focused, textField)
//        
//        if let coordinator = textField.delegate as? Coordinator, !focused {
//            coordinator.hide()
//        }
        
        guard textField.window?.firstResponder != textField.currentEditor() else {
            // Already focused; do nothing.
            return
        }

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
    }
    
    internal class Coordinator: NSObject, NSTextFieldDelegate {
        private var parent: PseudoTextField
        
        init(_ parent: PseudoTextField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField, let cursor = getCursor(textField) else { return }
//            if let _ = parent.viewModel.findCursoredRange(text: textField.stringValue, cursorLocation: cursor.0) {
//                show(textField)
//            } else {
//                hide()
//            }
            parent.text = textField.stringValue
        }
        
        func controlTextDidEndEditing(_ obj: Notification) {
            parent.onCommit()
        }
        
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            switch commandSelector {
            case #selector(NSResponder.moveDown(_:)):
                parent.viewModel.setKeyboard(.down)
                return true
            case #selector(NSResponder.moveUp(_:)):
                parent.viewModel.setKeyboard(.up)
                return true
            case #selector(NSResponder.insertNewline(_:)):
                guard parent.suggestionIndex != nil else { return false }
                parent.viewModel.setKeyboard(.enter)
                return true
            default:
                return false
            }
        }
    }
}
