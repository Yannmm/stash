//
//  SuggestionListView.swift
//  Stash
//
//  Created by Yan Meng on 2025/6/27.
//

import SwiftUI

struct SuggestionListView: View {
    let onTap: (String) -> Void
    @EnvironmentObject var hashtagManager: HashtagManager

    @State private var activeIndex: Int?
    @State private var isHovering: Bool = false
    
    
    var body: some View {
        List(Array(hashtagManager.hashtags.enumerated()), id: \.offset) { index, fruit in
                Text(fruit)
                    .background(activeIndex == index ? Color.accentColor.opacity(0.3) : Color.clear)
                    .onTapGesture {
                        activeIndex = index
                        isHovering = false
                    }
                    .onHover { hovering in
                        isHovering = hovering
                        if hovering {
                            activeIndex = index
                        }
                    }
            }
        .listStyle(.inset)
        .frame(width: 200, height: 150)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
        .onReceive(hashtagManager.keyboard, perform: { value in
//            print("xx -> \(activeIndex), \(value)")
            guard let direction = value else { return }
            switch direction {
            case .down: // ↓ Down arrow
                activeIndex = activeIndex == nil ? 0 : (activeIndex! + 1) % hashtagManager.hashtags.count
            case .up: // ↑ Up arrow
                // TODO: might out of range
                activeIndex = activeIndex == nil ? 0 : (activeIndex! - 1 + hashtagManager.hashtags.count) % hashtagManager.hashtags.count
            case .enter:
                onTap(hashtagManager.hashtags[activeIndex ?? 0])
            }
        })
    }
}



import SwiftUI

struct KeyDownViewModifier: ViewModifier {
    let handler: (NSEvent) -> Void

    func body(content: Content) -> some View {
        content
            .background(KeyDownRepresentable(handler: handler)) // ✅ fix here
    }
}

extension View {
    func onKeyDown(perform handler: @escaping (NSEvent) -> Void) -> some View {
        self.modifier(KeyDownViewModifier(handler: handler))
    }
}

struct KeyDownRepresentable: NSViewRepresentable {
    let handler: (NSEvent) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = KeyDownView(handler: handler)
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // No update needed
    }
    
    class KeyDownView: NSView {
        let handler: (NSEvent) -> Void
        
        init(handler: @escaping (NSEvent) -> Void) {
            self.handler = handler
            super.init(frame: .zero)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override var acceptsFirstResponder: Bool { true }
        
        override func keyDown(with event: NSEvent) {
            handler(event)
        }
        
        override func viewDidMoveToWindow() {
            DispatchQueue.main.async { [weak self] in
                self?.window?.makeFirstResponder(self)
            }
        }
    }
}
