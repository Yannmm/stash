//
//  Xxx.swift
//  Stash
//
//  Created by Yan Meng on 2026/2/14.
//

import SwiftUI

struct OsxFocusRingModifier: ViewModifier {
    var focused: Bool
    var cornerRadius: CGFloat = 6
    
    func body(content: Content) -> some View {
        content
            .overlay {
                ZStack {
                    // Base border (standard macOS separator)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
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
    }
}

extension View {
    func osxFocusRing(
        focused: Bool,
        cornerRadius: CGFloat = 6
    ) -> some View {
        self.modifier(
            OsxFocusRingModifier(
                focused: focused,
                cornerRadius: cornerRadius
            )
        )
    }
}
