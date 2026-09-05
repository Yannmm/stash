//
//  View+Modifier.swift
//  Stash
//
//  Created by Rayman on 2025/3/10.
//

import SwiftUI

extension View {
    func `if`<Content: View>(_ conditional: Bool, content: (Self) -> Content) -> some View {
        if conditional {
            return AnyView(content(self))
        } else {
            return AnyView(self)
        }
    }
    
    @ViewBuilder
    func ifAvailable<T: View>(
        _ availability: () -> Bool,
        transform: (Self) -> T
    ) -> some View {
        if availability() {
            transform(self)
        } else {
            self
        }
    }
}
