//
//  RelicsGuardian.swift
//  Stash
//
//  Created by Rayman on 2025/2/10.
//

import Foundation

class OkamuraCabinet: ObservableObject {
    @Published var entries: [any Entry] = []
    
    static let shared = OkamuraCabinet()
    
    init() {
        Task {
            try await load()
        }
    }
    
    func add(entry: any Entry) {
        entries.append(entry)
    }
    
    private func load() async throws {
//        if let data = UserDefaults.standard.data(forKey: "bookmarks"),
//           let savedBookmarks = try? JSONDecoder().decode([Bookmark].self, from: data) {
//            bookmarks = savedBookmarks
//        }
        try await Task.sleep(for: .seconds(1))
        
        self.entries = [
            Bookmark(id: UUID(), title: "A", url: URL(string: "https://www.baidu.com")!),
            Bookmark(id: UUID(), title: "B", url: URL(string: "https://www.google.com/?client=safari")!),
            Bookmark(id: UUID(), title: "C", url: URL(string: "https://htmlcheatsheet.com/css/")!),
            
            Directory(id: UUID(), title: "Dir1", children: [
                Bookmark(id: UUID(), title: "Dir1-1", url: URL(fileURLWithPath: "/Users/rayman/Downloads/report-7.pdf")),
            ]),
            Directory(id: UUID(), title: "Dir2", children: [
                Bookmark(id: UUID(), title: "Dir2-1", url: URL(string: "https://www.baidu.com")!),
                Bookmark(id: UUID(), title: "Dir2-2", url: URL(string: "https://www.google.com/?client=safari")!),
            ]),
        ]
    }
}
