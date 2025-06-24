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
        //        weak var currentTextField: NSTextField?
        private var panel: NSPanel!
        
        init(_ parent: HashtagTextField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            let text = textField.stringValue
            if let range = text.range(of: #"(^|(?<=\s))#\w*$"#, options: .regularExpression) {
                _suggest(textField)
            } else {
                //                hideSuggestions()
            }
            parent.text = textField.stringValue
        }
        
        func controlTextDidEndEditing(_ obj: Notification) {
            parent.onCommit()
        }
        
        func _suggest(_ textField: NSTextField) {
            //            guard let fieldEditor = textField.window?.fieldEditor(false, for: textField) as? NSTextView else { return }
            //            let selectedRange = fieldEditor.selectedRange()
            //            let cursorRect = fieldEditor.firstRect(forCharacterRange: selectedRange, actualRange: nil)
            //            createSuggestionWindow(at: cursorRect)
            guard let window = textField.window,
                  let textView = window.fieldEditor(true, for: textField) as? NSTextView else {
                return
            }
            
            let fullText = textView.string as NSString
            
            // Find the last "#" character
            let range = fullText.range(of: "#", options: .backwards)
            guard
                range.location != NSNotFound else {
                return
            }
            
            // Get the bounding rect for that character
            let glyphRange = textView.layoutManager?.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
            guard let glyphRange = glyphRange,
                  let layoutManager = textView.layoutManager,
                  let textContainer = textView.textContainer else {
                return
            }
            
            var rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
            rect.origin = textView.textContainerOrigin + rect.origin
            
            // Convert to screen coordinates
            let windowRect = textView.convert(rect, to: nil)
            let screenRect = textView.window?.convertToScreen(windowRect)
            
            guard let screenRect = screenRect else { return }
            
            
            //            makeSuggestionsView(anchor: screenRect)
            
            createSuggestionWindow(at: screenRect)
            
        }
        
        func createSuggestionWindow(at cursorRect: NSRect) {
            print("createSuggestionWindow called with cursorRect: \(cursorRect)")
            
            // Close existing panel if any
            panel?.close()
            
            // Create suggestions
            let suggestions = ["#work", "#personal", "#project", "#urgent"]
            
            // Calculate panel size
            let panelWidth: CGFloat = 120
            let itemHeight: CGFloat = 22
            let panelHeight = CGFloat(suggestions.count) * itemHeight
            
            // Position panel below cursor
            let panelRect = NSRect(
                x: cursorRect.origin.x,
                y: cursorRect.origin.y - 150,
                width: 200,
                height: 150
            )
            
            print("Panel rect: \(panelRect)")
            
            // Create panel that doesn't steal focus
            panel = NSPanel(
                contentRect: panelRect,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            
            panel.level = .popUpMenu
            panel.isOpaque = true
            panel.backgroundColor = NSColor.controlBackgroundColor
            panel.hasShadow = true
            panel.worksWhenModal = true
            panel.becomesKeyOnlyIfNeeded = false
            panel.acceptsMouseMovedEvents = true
            
            // Create content view
            //            let contentView = SuggestionListView(suggestions: suggestions, coordinator: self)
            
            //            panel.contentView = contentView
            panel.contentViewController = NSHostingController(rootView: SuggestionListView1(onTap: { x in }))
            panel.orderFront(nil)
            
            print("Panel created and ordered front")
            
            //            suggestionsPanel = panel
        }
        
        //        private func makeSuggestionsView(anchor: NSRect) {
        //            let width: CGFloat = 120
        //            let itemHeight: CGFloat = 22
        //            let height = CGFloat(["#Apple", "#Banana", "#Cherry"].count) * itemHeight
        //
        //            let panelRect = NSRect(
        //                x: anchor.origin.x,
        //                y: anchor.origin.y - 300,
        //                width: 200,
        //                height: 150
        //            )
        //            if panel == nil {
        //
        //
        //                panel = NSPanel(
        //                    contentRect: panelRect,
        //                    styleMask: [.borderless, .nonactivatingPanel],
        //                    backing: .buffered,
        //                    defer: false
        //                )
        //
        //                panel.level = .popUpMenu
        //                panel.isOpaque = true
        //                panel.backgroundColor = NSColor.controlBackgroundColor
        //                panel.hasShadow = true
        //                panel.worksWhenModal = true
        //                panel.becomesKeyOnlyIfNeeded = false
        //                panel.acceptsMouseMovedEvents = true
        //                panel.setFrame(panelRect, display: true)
        //            } else {
        //                panel.setFrame(panelRect, display: true)
        //            }
        //
        //
        //            // Create content view
        //            panel?.contentViewController = NSHostingController(rootView: SuggestionListView1(onTap: { x in }))
        //
        //            panel?.orderFront(nil)
        //        }
        //
        //        func hideSuggestions() {
        //            //            print("Hiding suggestions panel")
        //            panel?.close()
        //            panel = nil
        //            //            print("Suggestions panel closed and cleared")
        //        }
        
        //        func insertHashtag(_ hashtag: String) {
        //            print("🔸 Inserting hashtag: '\(hashtag)'")
        //            guard let textField = currentTextField else {
        //                print("❌ No current text field available")
        //                return
        //            }
        //
        //            // Replace the partial hashtag with the selected one
        //            let text = textField.stringValue
        //            print("🔸 Current text: '\(text)'")
        //
        //            // Use the same regex pattern as in controlTextDidChange
        //            if let range = text.range(of: #"(^|(?<=\s))#\w*$"#, options: .regularExpression) {
        //                let newText = text.replacingCharacters(in: range, with: hashtag)
        //                textField.stringValue = newText
        //                parent.text = newText
        //                print("✅ Updated text to: '\(newText)'")
        //
        //                // Move cursor to end of inserted hashtag
        //                if let editor = textField.currentEditor() {
        //                    let newPosition = newText.count
        //                    editor.selectedRange = NSRange(location: newPosition, length: 0)
        //                    print("✅ Moved cursor to position: \(newPosition)")
        //                }
        //            } else {
        //                print("❌ No hashtag pattern found to replace")
        //            }
        //
        //            print("✅ Text field remains focused and active - only closing suggestion panel")
        //        }
        //
        //
        //    }
    }
    
}

extension HashtagTextField {
    func font(_ font: NSFont) -> HashtagTextField {
        var copy = self
        copy.font = font
        return copy
    }
}

struct SuggestionListView1: View {
    let onTap: (String) -> Void
    let suggestions = ["#Apple", "#Banana", "#Cherry"]
    
    var body: some View {
        List(suggestions, id: \.self) { fruit in
            Text(fruit)
                .onTapGesture {
                    onTap(fruit)
                }
        }
        .frame(width: 200, height: 150)
    }
}

extension CGPoint {
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
}
