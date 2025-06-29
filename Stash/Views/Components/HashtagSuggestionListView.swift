//
//  SuggestionListView.swift
//  Stash
//
//  Created by Yan Meng on 2025/6/27.
//

import SwiftUI

struct HashtagSuggestionListView: View {
    let onTap: (String) -> Void
    @EnvironmentObject var hashtagManager: HashtagViewModel
    
    @State private var activeIndex: Int?
    @State private var isHovering: Bool = false
    
    
    var body: some View {
        ScrollViewReader { proxy in
            List(Array(hashtagManager.hashtags.enumerated()), id: \.offset) { index, fruit in
                HStack {
                    Text(fruit)
                        .foregroundColor(.secondary)
                        .padding(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10))
                    Spacer() // Fill remaining space
                    
                todo: 离开焦点，自动保存title
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowSeparator(.hidden)
                .listRowBackground(activeIndex == index ? Color.primary.opacity(0.3) : Color.clear)
                .frame(maxWidth: .infinity)
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
            .listStyle(.plain)
            .padding(0)
            .frame(width: 200, height: 150)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(6)
            .onChange(of: activeIndex) { index in
                withAnimation(.easeInOut(duration: 0.15)) {
                    proxy.scrollTo(index, anchor: .center)
                }
            }
            .onReceive(hashtagManager.keyboard, perform: { value in
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
