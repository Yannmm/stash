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
                .help("Create Bookmark")
                Button(action: {
                    addFolder()
                }) {
                    Image(systemName: "folder.badge.plus")
                }
                .buttonStyle(.plain)
                .help("Create Group")
                Spacer()
            }
            
            // Centered text
            (Text("Tip: ") + tip)
                .font(.headline)
                .frame(maxWidth: .infinity)
            
            HStack {
                Spacer()
                Button(action: {
                    NotificationCenter.default.post(name: .onToggleOutlineView, object: nil)
                }) {
                    Image(systemName: "list.bullet.indent")
                }
                .buttonStyle(.plain)
                .help("Expand / Collapse")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { time in
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
            (Text("Tap ") +
             Text(Image(systemName: "link.badge.plus")).font(.body) +
             Text(" to Create Bookmark")),
            (Text("Tap ") +
             Text(Image(systemName: "folder.badge.plus")).font(.body) +
             Text(" to Create Group")),
            Text("Hold CMD(⌘) Key for More"),
            Text("Tap ESC Key to Deselect Item"),
        ]
    }
}
