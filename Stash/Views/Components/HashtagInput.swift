//
//  EmphasisTextField.swift
//  Stash
//
//  Created by Rayman on 2025/6/18.
//

import SwiftUI
import Combine
import OrderedCollections
import AppKit

struct HashtagInput: NSViewRepresentable {
    let viewModel: HashtagInputViewModel
    let focused: Bool
    @Binding var hashtags: OrderedSet<String>?
    var font: NSFont?
    var onSubmit: (() -> Void)?
    
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
        textField.attributedStringValue = (hashtags ?? []).map({ $0 }).joined(separator: " ").highlightHashtags()
        return textField
    }
    
    func updateNSView(_ textField: NSTextField, context: Context) {
        context.coordinator.monitorCursor(focused, textField)
        textField.font = font
        context.coordinator.parent = self
        let text = (hashtags ?? []).map({ $0 }).joined(separator: " ")
        if !focused {
            textField.attributedStringValue = text.highlightHashtags()
            context.coordinator.hide()
        }
    }
    
    static func dismantleNSView(_ textField: NSTextField, coordinator: Coordinator) {
        coordinator.monitorCursor(false, textField)
        coordinator.hide()
    }
    
    internal class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: HashtagInput
        //        private weak var textField: NSTextField?
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
        
        private func produce(_ text: String) {
            parent.hashtags = OrderedSet(text.components(separatedBy: " ").filter({ $0.count > 1 && $0.hasPrefix("#") }))
        }
        
        func monitorCursor(_ focused: Bool, _ textField: NSTextField) {
            if let o = observer {
                NotificationCenter.default.removeObserver(o)
                observer = nil
            }
            
            if focused, let editor = textField.currentEditor() as? NSTextView {
                observer = NotificationCenter.default.addObserver(
                    forName: NSTextView.didChangeSelectionNotification,
                    object: editor,
                    queue: .main
                ) { [weak self] notification in
                    self?.hide()
                }
            }
        }
        
        func controlTextDidChange(_ notification: Notification) {
            guard let textField = notification.object as? NSTextField,
                  let textView = textField.currentEditor() as? NSTextView
            else { return }
            guard !textView.hasMarkedText() else { return }
            
            guard let textStorage = textView.textStorage else { return }
            
            let originalText = textView.string
            let cursorLocation = textView.selectedRange().location
            
            let (normalizedText, newCursor) = _normalize(
                text: originalText,
                cursorLocation: cursorLocation
            )
            
            textStorage.beginEditing()
            
            if normalizedText != originalText {
                textStorage.replaceCharacters(
                    in: NSRange(location: 0,
                                length: (originalText as NSString).length),
                    with: normalizedText
                )
            }
            
            textStorage.endEditing()
            
            if normalizedText != originalText {
                textView.setSelectedRange(NSRange(location: newCursor, length: 0))
            }
            
            let text = textView.string
            produce(text)
            
            if let _ = findCursoredRange(
                text: text,
                cursorLocation: textView.selectedRange().location
            ) {
                show(textView)
            } else {
                hide()
            }
        }
        
        func controlTextDidEndEditing(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            textField.attributedStringValue = textField.stringValue.highlightHashtags()
        }
        
        func control(
            _ control: NSControl,
            textView: NSTextView,
            doCommandBy commandSelector: Selector
        ) -> Bool {
            switch commandSelector {
            case #selector(NSResponder.moveDown(_:)):
                parent.viewModel.keyboardAction = .down
                return true
            case #selector(NSResponder.moveUp(_:)):
                parent.viewModel.keyboardAction = .up
                return true
            case #selector(NSResponder.insertNewline(_:)):
                if panel != nil, parent.viewModel.suggestionIndex != nil {
                    parent.viewModel.keyboardAction = .enter
                    return true
                }
                // No suggestion panel: propagate submit to SwiftUI (NSTextField doesn't trigger onSubmit)
                parent.onSubmit?()
                return true
            case #selector(NSResponder.cancelOperation(_:)):
                hide()
                return true
            default:
                return false
            }
        }
        
        private func _normalize(
            text: String,
            cursorLocation: Int
        ) -> (String, Int) {
            
            let nsText = text as NSString
            let length = nsText.length
            
            var result = ""
            var newCursor = cursorLocation
            var index = 0
            
            while index < length {
                
                if nsText.character(at: index) == 32 {
                    result.append(" ")
                    index += 1
                    continue
                }
                
                let tokenStart = index
                var tokenEnd = index
                
                while tokenEnd < length,
                      nsText.character(at: tokenEnd) != 32 {
                    tokenEnd += 1
                }
                
                let tokenRange = NSRange(
                    location: tokenStart,
                    length: tokenEnd - tokenStart
                )
                
                let token = nsText.substring(with: tokenRange)
                
                let isValid =
                token.hasPrefix("#") &&
                !token.dropFirst().contains("#")
                
                if isValid {
                    result.append(token)
                } else {
                    
                    let removedLength = tokenRange.length
                    
                    if cursorLocation > tokenStart &&
                        cursorLocation <= tokenEnd {
                        newCursor = (result as NSString).length
                    }
                    
                    if cursorLocation > tokenEnd {
                        newCursor -= removedLength
                    }
                }
                
                index = tokenEnd
            }
            
            let utf16Length = (result as NSString).length
            newCursor = max(0, min(newCursor, utf16Length))
            
            return (result, newCursor)
        }
        
        private func show(_ textView: NSTextView) {
            if let anchor = _whereToAnchor(textView) {
                parent.viewModel.takens = parent.hashtags
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
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = true
            panel.worksWhenModal = true
            panel.becomesKeyOnlyIfNeeded = false
            panel.acceptsMouseMovedEvents = true
            
            let hostingController = NSHostingController(rootView: HashtagSuggestionListView(onTap: { [weak self] hashtag in
                self?._insert(hashtag, textView)
                self?.hide()
            }).environmentObject(parent.viewModel))
            panel.contentViewController = hostingController
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
                let text = result.0
                produce(text)
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
