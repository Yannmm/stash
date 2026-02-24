//
//  TitleInputField.swift
//  Stash
//
//  Created by Rayman on 2025/2/27.
//

import SwiftUI
import Kingfisher

struct TitleField: View {
    @Binding var title: String?
    let icon: Icon?
    @FocusState.Binding var focusedField: EntryEditor.Field?
    let disabled: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            iconView
            Divider()
            TextField("Title can be auto generated from path", text: $title ?? "")
                .textFieldStyle(.plain)
                .focused($focusedField, equals: .title)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .cornerRadius(6)
        .background(Color(nsColor: .controlBackgroundColor))
        .osxFocusRing(focused: focusedField == .title, disabled: disabled)
    }
    
    @ViewBuilder
    private var iconView: some View {
        SwiftUI.Group {
            if let i = icon {
                switch (i) {
                case .system(let name):
                    Image(systemName: name)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: NSImage.Constant.side1, height: NSImage.Constant.side1)
                        .foregroundStyle(Color.theme)
                case .favicon(let url):
                    KFImage.url(url)
                        .appendProcessor(EmptyFaviconReplacer(url: url))
                        .scaleFactor(NSScreen.main?.backingScaleFactor ?? 2)
                        .cacheOriginalImage()
                        .loadDiskFileSynchronously()
                        .forceRefresh()
                        .onSuccess { result in }
                        .onFailure { error in }
                        .onFailureImage(NSImage.drawFavicon(from: url.firstDomainLetter))
                        .resizable()
                        .frame(width: NSImage.Constant.side1, height: NSImage.Constant.side1)
                case .local(let url):
                    Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: NSImage.Constant.side1, height: NSImage.Constant.side1)
                }
            } else {
                Image(systemName: "questionmark.circle.dashed")
                    .resizable()
                    .frame(width: 16, height: 16)
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            }
            
        }
        .animation(.easeInOut(duration: 0.3), value: icon)
    }
}
