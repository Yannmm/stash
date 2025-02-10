//
//  RelicsGuardian.swift
//  Stash
//
//  Created by Rayman on 2025/2/10.
//

import Foundation

class RelicsGuardian: ObservableObject {
    static let shared = RelicsGuardian()
    
    @Published var relics: [Relic] = []
    
    init() {
        Task {
            try await load()
        }
    }
    
//    func addBookmark(url: URL) {
//        let newBookmark = Bookmark(
//            id: UUID(),
//            title: url.lastPathComponent,
//            url: url
//        )
//        bookmarks.insert(newBookmark, at: 0)
//        saveBookmarks()
//    }
    
//    private func saveBookmarks() {
//        if let data = try? JSONEncoder().encode(bookmarks) {
//            UserDefaults.standard.set(data, forKey: "bookmarks")
//        }
//    }
    
    private func load() async throws {
//        if let data = UserDefaults.standard.data(forKey: "bookmarks"),
//           let savedBookmarks = try? JSONDecoder().decode([Bookmark].self, from: data) {
//            bookmarks = savedBookmarks
//        }
        try await Task.sleep(for: .seconds(3))
        
        relics = [
            Relic(id: UUID(), title: "Baidu.com", url: URL(string: "https://www.baidu.com")!),
            Relic(id: UUID(), title: "Google", url: URL(string: "https://www.google.com/?client=safari")!)
        ]
    }
}
