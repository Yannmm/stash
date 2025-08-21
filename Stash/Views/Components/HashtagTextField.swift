//
//  EmphasisTextField.swift
//  Stash
//
//  Created by Rayman on 2025/6/18.
//

import SwiftUI
import Combine

struct HashtagTextField: NSViewRepresentable {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var viewModel: HashtagViewModel
    @Binding var text: String
    @State var suggestionIndex: Int?
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
    
    internal class Coordinator: NSObject, NSTextFieldDelegate {
        private var parent: HashtagTextField
        
        private var panel: NSPanel!
        
        private var cancellables = Set<AnyCancellable>()
        
        private var observer: NSObjectProtocol?
        
        init(_ parent: HashtagTextField) {
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
        
        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField, let cursor = getCursor(textField) else { return }
            if let _ = parent.viewModel.findCursoredRange(text: textField.stringValue, cursorLocation: cursor.0) {
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
                parent.viewModel.keyboardAction = .down
                return true
            case #selector(NSResponder.moveUp(_:)):
                parent.viewModel.keyboardAction = .up
                return true
            case #selector(NSResponder.insertNewline(_:)):
                guard parent.suggestionIndex != nil else { return false }
                parent.viewModel.keyboardAction = .enter
                return true
            default:
                return false
            }
        }
        
        private func show(_ textField: NSTextField) {
            if let anchor = _whereToAnchor(textField) {
                parent.suggestionIndex = nil
                _makePanel(anchor, textField)
            } else {
                hide()
            }
        }
        
        private func _whereToAnchor(_ textField: NSTextField) -> NSRect? {
            guard let cursor = getCursor(textField),
                  let range = parent.viewModel.findCursoredRange(text: textField.stringValue, cursorLocation: cursor.0) else { return nil }
            
            let textView = cursor.1
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
        
        private func _makePanel(_ anchor: NSRect, _ textField: NSTextField) {
            hide()
            _setupPanel(anchor, textField)
        }
        
        private func _setupPanel(_ anchor: NSRect, _ textField: NSTextField) {
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
            
            panel.contentViewController = NSHostingController(rootView: HashtagSuggestionListView(index: parent.$suggestionIndex, onTap: { [weak self] hashtag in
                self?._insert(hashtag, textField)
                self?.hide()
            }).environmentObject(parent.viewModel))
            panel.orderFront(nil)
        }
        
        func hide() {
            panel?.close()
            panel = nil
        }
        
        private func _insert(_ hashtag: String, _ textField: NSTextField) {
            guard let cursor = getCursor(textField)?.0 else { return }
            if let result = parent.viewModel.insert(text: textField.stringValue, hashtag: hashtag, cursorLocation: cursor) {
                textField.attributedStringValue = result.0.highlightHashtags()
                if let editor = textField.currentEditor() {
                    editor.selectedRange = result.1
                    editor.scrollRangeToVisible(result.1)
                }
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
    }
}

extension HashtagTextField {
    func font(_ font: NSFont) -> HashtagTextField {
        var copy = self
        copy.font = font
        return copy
    }
}


