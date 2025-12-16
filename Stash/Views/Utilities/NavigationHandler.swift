//
//  NavigationHandler.swift
//  Stash
//
//  Created by Yan Meng on 2025/12/16.
//

import SwiftUI

struct NavigationHandler<Content>: View where Content: View {
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        if #available(iOS 16, *) {
            NavigationStack(root: content)
        } else {
            NavigationView(content: content)
        }
    }
}
