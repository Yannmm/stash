import SwiftUI
import AppKit

// MARK: - Data Model
struct Bookmark: Identifiable, Codable {
    let id: UUID
    let title: String
    let url: URL
}

// MARK: - State Management
class BookmarkManager: ObservableObject {
    static let shared = BookmarkManager()
    @Published var bookmarks: [Bookmark] = []
    
    init() {
        loadBookmarks()
    }
    
    func addBookmark(url: URL) {
        let newBookmark = Bookmark(
            id: UUID(),
            title: url.lastPathComponent,
            url: url
        )
        bookmarks.insert(newBookmark, at: 0)
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

// MARK: - Drag & Drop Window
struct DropWindowView: View {
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

// MARK: - Menu Bar List
struct BookmarkListView: View {
    @EnvironmentObject var manager: BookmarkManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button("Show Drop Window") {
                NSApp.activate(ignoringOtherApps: true)
                AppDelegate.shared.showDropWindow()
            }
            .buttonStyle(PlainButtonStyle())
            
            Divider()
            
            List(manager.bookmarks) { bookmark in
                HStack {
                    VStack(alignment: .leading) {
                        Text(bookmark.title)
                        Text(bookmark.url.absoluteString)
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    Spacer()
                    Button(action: { copyToClipboard(bookmark.url) }) {
                        Image(systemName: "doc.on.doc")
                    }
                    Button(action: { openURL(bookmark.url) }) {
                        Image(systemName: "arrowshape.turn.up.right")
                    }
                }
            }
            .listStyle(SidebarListStyle())
        }
        .frame(width: 300, height: 400)
    }
    
    private func copyToClipboard(_ url: URL) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url.absoluteString, forType: .URL)
    }
    
    private func openURL(_ url: URL) {
        NSWorkspace.shared.open(url)
    }
}

// MARK: - App Main
// @main
// struct BookmarkCollectorApp: App {
//     @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
//     var body: some Scene {
//         Settings {
//             EmptyView()
//         }
//     }
// }