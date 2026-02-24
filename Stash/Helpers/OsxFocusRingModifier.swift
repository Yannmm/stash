//
//  Xxx.swift
//  Stash
//
//  Created by Yan Meng on 2026/2/14.
//

import SwiftUI
import AppKit

// MARK: - Arrow cursor overlay for disabled fields

private class ArrowCursorNSView: NSView {
    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .arrow)
    }
}

private struct ArrowCursorOverlay: NSViewRepresentable {
    func makeNSView(context: Context) -> ArrowCursorNSView { ArrowCursorNSView() }
    func updateNSView(_ nsView: ArrowCursorNSView, context: Context) {}
}

// MARK: -

struct OsxFocusRingModifier: ViewModifier {
    var focused: Bool
    var disabled: Bool
    var cornerRadius: CGFloat = 6
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if disabled {
                    ArrowCursorOverlay()
                }
            }
            .overlay {
                ZStack {
                    // Base border (standard macOS separator)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color(nsColor: .disabledControlTextColor), lineWidth: 1)
                        .allowsHitTesting(false)
                    
                    // macOS-style focus ring
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            Color(nsColor: .keyboardFocusIndicatorColor)
                                .opacity(focused ? 1 : 0),
                            lineWidth: 3
                        )
                        .padding(focused ? -1 : -4)
                        .scaleEffect(focused ? 1.0 : 1.06)
                        .shadow(
                            color: Color(nsColor: .keyboardFocusIndicatorColor)
                                .opacity(focused ? 1 : 0),
                            radius: focused ? 3 : 0
                        )
                        .allowsHitTesting(false)
                }
            }
            .animation(.spring(response: 0.20, dampingFraction: 0.78, blendDuration: 0.10), value: focused)
            .disabled(disabled)
    }
    
    private var borderColor: Color {
        if !disabled && !focused {
            return Color(nsColor: NSColor.separatorColor)
        } else if focused {
            return Color(nsColor: NSColor.controlAccentColor)
        }
        return Color(nsColor: NSColor.disabledControlTextColor)
    }
}

extension View {
    func osxFocusRing(
        focused: Bool,
        disabled: Bool,
        cornerRadius: CGFloat = 6
    ) -> some View {
        self.modifier(
            OsxFocusRingModifier(
                focused: focused,
                disabled: disabled,
                cornerRadius: cornerRadius
            )
        )
    }
}
