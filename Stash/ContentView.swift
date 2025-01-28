import SwiftUI

struct Bookmark: Identifiable, Codable {
    let id: UUID
    let title: String
    let url: URL
}

struct ContentView: View {
    @State private var bookmarks: [Bookmark] = []
    @State private var dropHighlight = false
    
    var body: some View {
        VStack {
            Text("Drag files or URLs here")
                .font(.title)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(dropHighlight ? Color.blue.opacity(0.2) : Color.clear)
                .onDrop(of: [.url, .fileURL], isTargeted: $dropHighlight) { providers in
                    handleDrop(providers: providers)
                }
            
            List(bookmarks) { bookmark in
                HStack {
                    VStack(alignment: .leading) {
                        Text(bookmark.title)
                        Text(bookmark.url.absoluteString)
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    Spacer()
                    Button(action: {
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.setString(bookmark.url.absoluteString, forType: .URL)
                    }) {
                        Image(systemName: "doc.on.doc")
                    }
                    Button(action: {
                        NSWorkspace.shared.open(bookmark.url)
                    }) {
                        Image(systemName: "arrowshape.turn.up.right")
                    }
                }
            }
        }
        .onAppear(perform: loadBookmarks)
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.canLoadObject(ofClass: URL.self) {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url = url {
                        addBookmark(url: url)
                    }
                }
            } else {
                _ = provider.loadItem(forTypeIdentifier: kUTTypeFileURL as String, options: nil) { data, _ in
                    if let data = data as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        addBookmark(url: url)
                    }
                }
            }
        }
        return true
    }
    
    private func addBookmark(url: URL) {
        let newBookmark = Bookmark(
            id: UUID(),
            title: url.lastPathComponent,
            url: url
        )
        bookmarks.append(newBookmark)
        saveBookmarks()
    }
    
    private func saveBookmarks() {
        if let data = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(data, forKey: "bookmarks")
        }
    }
    
    private func loadBookmarks() {
        if let data = UserDefaults.standard.data(forKey: "bookmarks"),
           let savedBookmarks = try? JSONDecoder().decode([Bookmark].self, from: data) {
            bookmarks = savedBookmarks
        }
    }
}

//@main
//struct BookmarkCollectorApp: App {
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//                .frame(minWidth: 400, minHeight: 400)
//        }
//    }
//}

