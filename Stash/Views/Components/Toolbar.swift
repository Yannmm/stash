//
//  Toolbar.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/24.
//

import SwiftUI

struct Toolbar: View {
    @Binding var present: Bool
    @State var tip = Constant.tips[0]
    @State private var timer: Timer?
    
    let addFolder: () -> Void
    
    var body: some View {
        ZStack {
            // Left-aligned buttons
            HStack {
                Button(action: {
                    present = true
                }) {
                    Image(systemName: "link.badge.plus")
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    addFolder()
                }) {
                    Image(systemName: "folder.badge.plus")
                }
                .buttonStyle(.plain)
                Spacer()
            }
            
            // Centered text
            Text("Tip: \(tip)")
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { time in
                let seconds = Calendar.current.component(.second, from: Date())
                tip = Constant.tips[seconds % Constant.tips.count]
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
        //        .background(
        //                        GeometryReader { geometry in
        //                            Color.clear
        //                                .onAppear {
        //                                    print("Height: \(geometry.size.height)")
        //                                }
        //                                .onChange(of: geometry.size) { newSize in
        //                                    print("New Height: \(newSize.height)")
        //                                }
        //                        }
        //                    )
    }
}

fileprivate extension Toolbar {
    struct Constant {
        static let tips = [
            "Hold CMD(⌘) Key for More Info.",
            "Tap ESC Key to Deselect an Item.",
            "Support Network, local or VNC."
        ]
    }
}
