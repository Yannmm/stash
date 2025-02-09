//
//  DragAndDropView.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/9.
//

import SwiftUI

struct DragAndDropView: View {
    @State private var dropHighlight = false
    @EnvironmentObject var manager: BookmarkManager
    
    var body: some View {
        VStack {
            Text("Drag files or URLs here")
                .font(.title)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(dropHighlight ? Color.blue.opacity(0.2) : Color.clear)
                .onDrop(of: [.url, .fileURL], isTargeted: $dropHighlight) { providers in
                    handleDrop(providers: providers)
                    return true
                }
        }
        .frame(width: 400, height: 400)
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            if provider.canLoadObject(ofClass: URL.self) {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url = url {
                        DispatchQueue.main.async {
                            manager.addBookmark(url: url)
                        }
                    }
                }
            } else {
                _ = provider.loadItem(forTypeIdentifier: kUTTypeFileURL as String, options: nil) { data, _ in
                    if let data = data as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        DispatchQueue.main.async {
                            manager.addBookmark(url: url)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    DragAndDropView()
}
