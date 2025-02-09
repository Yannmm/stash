//
//  BookmarkListManager.swift
//  Stash
//
//  Created by Yan Meng on 2025/2/9.
//

import Foundation

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
