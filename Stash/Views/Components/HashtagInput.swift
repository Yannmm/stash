//
//  EmphasisTextField.swift
//  Stash
//
//  Created by Rayman on 2025/6/18.
//

import SwiftUI
import Combine

struct HashtagInput: NSViewRepresentable {
    @EnvironmentObject var viewModel: HashtagInputViewModel
    @Binding var text: String
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
        textField.placeholderString = "Typing `#` to enter hashtag, space to separate"
        textField.attributedStringValue = text.highlightHashtags()
        return textField
    }
    
    func updateNSView(_ textField: NSTextField, context: Context) {
        textField.font = font
        
        context.coordinator.monitorCursor(focused, textField)
        
        if let coordinator = textField.delegate as? Coordinator, !focused {
            coordinator.hide()
        }
        
        guard textField.window?.firstResponder != textField.currentEditor() else {
            // Already focused; do nothing.
            return
        }
        
        textField.attributedStringValue = text.highlightHashtags()
        
        // Move cursor to end if it just became first responder
        DispatchQueue.main.async {
            if let editor = textField.currentEditor() {
                let range = NSRange(location: (editor.string as NSString).length, length: 0)
                editor.selectedRange = range
                editor.scrollRangeToVisible(range)
            }
        }
    }
    
    internal class Coordinator: NSObject, NSTextFieldDelegate, NSTextViewDelegate {
        private var parent: HashtagInput
        private var panel: NSPanel!
        private var observer: NSObjectProtocol?
        
        init(_ parent: HashtagInput) {
            self.parent = parent
        }
        
        deinit {
            if let o = observer {
                NotificationCenter.default.removeObserver(o)
                observer = nil
            }
        }
        
        func monitorCursor(_ focused: Bool, _ textField: NSTextField) {
            if focused, let editor = textField.currentEditor() as? NSTextView {
                observer = NotificationCenter.default.addObserver(
                    forName: NSTextView.didChangeSelectionNotification,
                    object: editor,
                    queue: .main
                ) { [weak self] notification in
                    self?.hide()
                }
            } else {
                if let o = observer {
                    NotificationCenter.default.removeObserver(o)
                    observer = nil
                }
            }
        }
        
        // 🔥 This is where you get the NSTextView
        func controlTextDidBeginEditing(_ obj: Notification) {
            guard
                let textField = obj.object as? NSTextField,
                let window = textField.window,
                let textView = window.fieldEditor(true, for: textField) as? NSTextView
            else { return }
            
            textView.delegate = self
        }
        
        
        func textView(
            _ textView: NSTextView,
            shouldChangeTextIn range: NSRange,
            replacementString string: String?
        ) -> Bool {
            guard let string = string else { return true }
            
            let currentText = textView.string as NSString
            let newText = currentText.replacingCharacters(in: range, with: string)
            // Empty is fine
            if newText.isEmpty { return true }
            
            let tokens = newText.split(separator: " ", omittingEmptySubsequences: false)
            
            for token in tokens {
                if token.isEmpty { continue } // allow trailing space + typing
                
                // Every token must start with #
                if !token.hasPrefix("#") {
                    let fullRange = forwardSearch(
                        " ",
                        in: currentText,
                        start: range.location
                    )
                    
                    // Replace entire hashtag with empty string
                    textView.textStorage?.replaceCharacters(
                        in: fullRange,
                        with: ""
                    )
                    
                    // Move cursor to original '#'
                    textView.setSelectedRange(
                        NSRange(location: fullRange.location, length: 0)
                    )
                    
                    return false
                }
                
                // Remaining chars must be alphanumeric
                let body = token.dropFirst()
                if !body.allSatisfy({ $0.isLetter || $0.isNumber }) {
                    return false
                }
            }
            
            return true
        }
        
        private func forwardSearch(
            _ character: String,
            in text: NSString,
            start location: Int
        ) -> NSRange {
            let start = location
            var end = location
            
            // Move forward until space or end
            while end < text.length {
                let char = text.substring(with: NSRange(location: end, length: 1))
                if char == character { break }
                end += 1
            }
            
            return NSRange(location: start, length: end - start)
        }
        
        
        func textDidChange(_ notification: Notification) {
            
            guard let textView = notification.object as? NSTextView else { return }
            
            let updatedText = textView.string
            
            parent.text = updatedText
            
            // If you need cursor logic:
            let cursorLocation = textView.selectedRange().location
            
            if let _ = findCursoredRange(
                text: updatedText,
                cursorLocation: cursorLocation
            ) {
                show(textView)
            } else {
                hide()
            }
        }
        
        func controlTextDidEndEditing(_ obj: Notification) {
            parent.onCommit()
        }
        
        func textView(_ textView: NSTextView, doCommandBy: Selector) -> Bool {
            switch doCommandBy {
            case #selector(NSResponder.moveDown(_:)):
                parent.viewModel.keyboardAction = .down
                return true
            case #selector(NSResponder.moveUp(_:)):
                parent.viewModel.keyboardAction = .up
                return true
            case #selector(NSResponder.insertNewline(_:)):
                guard panel != nil else { return false } // if panel is not shown, hit enter will quit editing.
                guard parent.viewModel.suggestionIndex != nil else { return false }
                parent.viewModel.keyboardAction = .enter
                return true
            default:
                return false
            }
        }
        
        private func show(_ textView: NSTextView) {
            if let anchor = _whereToAnchor(textView) {
                _makePanel(anchor, textView)
            } else {
                hide()
            }
        }
        
        private func _whereToAnchor(_ textView: NSTextView) -> NSRect? {
            guard
                let range = findCursoredRange(text: textView.string, cursorLocation: textView.selectedRange().location) else { return nil }
            
            let hashtag = (textView.string as NSString).substring(with: range)
            
            parent.viewModel.query = hashtag
            
            // Get the bounding rect for that character
            guard let glyphRange = textView.layoutManager?.glyphRange(forCharacterRange: range, actualCharacterRange: nil),
                  let layoutManager = textView.layoutManager,
                  let textContainer = textView.textContainer else { return nil }
            
            var rect1 = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
            rect1.origin = textView.textContainerOrigin + rect1.origin
            let rect2 = textView.convert(rect1, to: nil)
            let rect3 = textView.window?.convertToScreen(rect2)
            guard let result = rect3 else { return nil }
            return result
        }
        
        private func _makePanel(_ anchor: NSRect, _ textView: NSTextView) {
            hide()
            _setupPanel(anchor, textView)
        }
        
        private func _setupPanel(_ anchor: NSRect, _ textView: NSTextView) {
            guard !parent.viewModel.hashtags.isEmpty else { return }
            
            let width: CGFloat = 200
            let height: CGFloat = 150
            
            // Get screen bounds to check available space
            let screenFrame = NSScreen.main?.frame ?? NSRect.zero
            
            // Calculate available space below and above the cursor
            let spaceBelow = anchor.origin.y - screenFrame.minY
            let spaceAbove = screenFrame.maxY - anchor.origin.y
            
            // Determine whether to position panel above or below cursor
            let above = spaceBelow < height && spaceAbove >= height
            
            let y: CGFloat
            if above {
                // Position above cursor
                y = anchor.origin.y + anchor.height
            } else {
                // Position below cursor (default behavior)
                y = anchor.origin.y - height
            }
            
            let contentRect = NSRect(
                x: anchor.origin.x,
                y: y,
                width: width,
                height: height
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
                self?._insert(hashtag, textView)
                self?.hide()
            }).environmentObject(parent.viewModel))
            panel.orderFront(nil)
        }
        
        func hide() {
            panel?.close()
            panel = nil
        }
        
        private func _insert(_ hashtag: String, _ textView: NSTextView) {
            let cursor = textView.selectedRange().location
            if let result = insert(text: textView.string, hashtag: hashtag, cursorLocation: cursor) {
                textView.string = result.0
                textView.selectedRange = result.1
                textView.scrollRangeToVisible(result.1)
                parent.text = result.0
            }
        }
        
        private func getCursor(_ textField: NSTextField) -> (Int, NSTextView)? {
            guard let window = textField.window,
                  let textView = window.fieldEditor(true, for: textField) as? NSTextView else {
                return nil
            }
            return (textView.selectedRange().location, textView)
        }
        
        @discardableResult
        private func findCursoredRange(text: String, cursorLocation: Int) -> NSRange? {
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            let matches = String.RegexConstant.regex1.matches(in: text, range: range)
            if let cursored = matches.filter({ (cursorLocation >= $0.range.location)
                && (cursorLocation <= $0.range.location + $0.range.length) }).first {
                return cursored.range
            } else {
                return nil
            }
        }
        
        private func insert(text: String, hashtag: String, cursorLocation: Int) -> (String, NSRange)? {
            if let cursored = findCursoredRange(text: text, cursorLocation: cursorLocation),
               let range = Range(cursored, in: text) {
                let updated = text.replacingCharacters(in: range, with: hashtag)
                let cursorRange = NSRange(updated.range(of: hashtag)!, in: updated)
                let cursorRange1 = NSRange(location: cursorRange.location + cursorRange.length, length: 0)
                return (updated, cursorRange1)
            } else {
                return nil
            }
        }
    }
}

extension HashtagInput {
    func font(_ font: NSFont) -> HashtagInput {
        var copy = self
        copy.font = font
        return copy
    }
}
