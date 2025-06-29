//
//  EmphasisTextField.swift
//  Stash
//
//  Created by Rayman on 2025/6/18.
//

import SwiftUI
import Combine

struct HashtagTextField: NSViewRepresentable {
    @EnvironmentObject var hashtagManager: HashtagViewModel
    @Binding var text: String
    let focused: Bool
    var font: NSFont?
    var onCommit: () -> Void = {}
    
    @State private var selectedIndex = 0
    
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
    
    func updateNSView(_ textField: NSTextField, context: Context) {
        textField.font = font
        
        if let coordinator = textField.delegate as? Coordinator, !focused {
            coordinator.hide()
        }
        
        guard textField.window?.firstResponder != textField.currentEditor() else {
            // Already focused; do nothing.
            return
        }
        textField.stringValue = text
        
        // Move cursor to end if it just became first responder
        DispatchQueue.main.async {
            if let editor = textField.currentEditor() {
                let range = NSRange(location: (editor.string as NSString).length, length: 0)
                editor.selectedRange = range
                editor.scrollRangeToVisible(range)
            }
        }
    }
    
    internal class Coordinator: NSObject, NSTextFieldDelegate {
        private var parent: HashtagTextField
        
        private var panel: NSPanel!
        
        private var cancellables = Set<AnyCancellable>()
        
        init(_ parent: HashtagTextField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            let text = textField.stringValue
            if let range = text.range(of: #"(^|(?<=\s))#\w*$"#, options: .regularExpression) {
                show(textField)
            } else {
                hide()
            }
            parent.text = textField.stringValue
        }
        
        func controlTextDidEndEditing(_ obj: Notification) {
            parent.onCommit()
        }
        
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            switch commandSelector {
            case #selector(NSResponder.moveDown(_:)):
                parent.hashtagManager.setKeyboard(.down)
                return true
            case #selector(NSResponder.moveUp(_:)):
                parent.hashtagManager.setKeyboard(.up)
                return true
            case #selector(NSResponder.insertNewline(_:)):
                parent.hashtagManager.setKeyboard(.enter)
                return true
            default:
                return false
            }
        }
        
        private func show(_ textField: NSTextField) {
            if let anchor = _whereToAnchor(textField) {
                _makePanel(anchor, textField)
            } else {
                hide()
            }
        }
        
        private func _whereToAnchor(_ textField: NSTextField) -> (NSRect, String)? {
            guard let window = textField.window,
                  let textView = window.fieldEditor(true, for: textField) as? NSTextView else {
                return nil
            }
            
            // Find the first "#" character to the left of cursor
            let cursor = textView.selectedRange().location
            let text = (textView.string as NSString).substring(to: cursor)
            
            let range = (text as NSString).range(of: "#", options: .backwards)
            guard range.location != NSNotFound else { return nil }
            
            let hashtag = (textView.string as NSString).substring(with: NSRange(location: range.location, length: cursor - range.location))
            
            parent.hashtagManager.filter = hashtag
            
            // Get the bounding rect for that character
            guard let glyphRange = textView.layoutManager?.glyphRange(forCharacterRange: range, actualCharacterRange: nil),
                  let layoutManager = textView.layoutManager,
                  let textContainer = textView.textContainer else { return nil }
            
            var rect1 = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
            rect1.origin = textView.textContainerOrigin + rect1.origin
            let rect2 = textView.convert(rect1, to: nil)
            let rect3 = textView.window?.convertToScreen(rect2)
            guard let result = rect3 else { return nil }
            return (result, hashtag)
        }
        
        private func _makePanel(_ anchor: (NSRect, String), _ textField: NSTextField) {
            hide()
            _setupPanel(anchor, textField)
        }
        
        private func _setupPanel(_ anchor: (NSRect, String), _ textField: NSTextField) {
            // Calculate panel size
            let panelWidth: CGFloat = 120
            let itemHeight: CGFloat = 22
            //            let panelHeight = CGFloat(suggestions.count) * itemHeight
            
            // Position panel below cursor
            let contentRect = NSRect(
                x: anchor.0.origin.x,
                y: anchor.0.origin.y - 150,
                width: 200,
                height: 150
            )
            
            panel = NSPanel(
                contentRect: contentRect,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            
            panel.level = .statusBar
            panel.isOpaque = true
            panel.backgroundColor = NSColor.clear
            panel.hasShadow = true
            panel.worksWhenModal = true
            panel.becomesKeyOnlyIfNeeded = false
            panel.acceptsMouseMovedEvents = true
            
            panel.contentViewController = NSHostingController(rootView: HashtagSuggestionListView(onTap: { [weak self] hashtag in
                self?._insert(hashtag, textField)
                self?.hide()
            }).environmentObject(parent.hashtagManager))
            panel.orderFront(nil)
        }
        
        func hide() {
            panel?.close()
            panel = nil
        }
        
        private func _insert(_ hashtag: String, _ textField: NSTextField) {
            // Find the first "#" character to the left of cursor
            guard let window = textField.window,
                  let textView = window.fieldEditor(true, for: textField) as? NSTextView else {
                return
            }
            let cursor = textView.selectedRange().location
            let text = (textView.string as NSString).substring(to: cursor)
            //            let range = (text as NSString).range(of: "#", options: .backwards)
            //            guard range.location != NSNotFound else { return }
            let rest = (textView.string as NSString).substring(from: cursor)
            
            if let range = text.range(of: #"(^|(?<=\s))#\w*$"#, options: .regularExpression) {
                let inserted = text.replacingCharacters(in: range, with: hashtag)
                let newText = inserted + rest
                textField.stringValue = newText
                if let editor = textField.currentEditor() {
                    let range = NSRange(location: (inserted as NSString).length, length: 0)
                    editor.selectedRange = range
                    editor.scrollRangeToVisible(range)
                }
                parent.text = newText
            }
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
