//
//  Toolbar.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/24.
//

import SwiftUI

struct Toolbar: View {
    @Binding var present: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Left side buttons
            HStack(spacing: 8) {
                Button(action: {
                    present = true
                }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)
                
                Button(action: { print("Delete clicked") }) {
                    Image(systemName: "minus")
                }
                .buttonStyle(.plain)
            }
            Spacer()
            // Center title
            Text("SwiftUI")
                .font(.headline)
            Spacer()
            // Right side buttons
            HStack(spacing: 8) {
                Button(action: { print("Search clicked") }) {
                    Image(systemName: "magnifyingglass")
                }
                .buttonStyle(.plain)
                
                Button(action: { print("Share clicked") }) {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

#Preview {
//    Toolbar(present: <#T##Binding<Bool>#>)
}
