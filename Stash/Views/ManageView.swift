//
//  CollectionView.swift
//  Stash
//
//  Created by Yan Meng on 2025/12/16.
//

import SwiftUI
import AppKit

// Refer to https://dribbble.com/shots/14567500-Bookmark-app-v2

// MARK: - Data Models

struct SidebarItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let icon: String
    let count: Int?
    
    init(name: String, icon: String, count: Int? = nil) {
        self.name = name
        self.icon = icon
        self.count = count
    }
}

struct Collection: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let icon: String
}

// MARK: - CollectionView

struct CollectionView: View {
    @State private var searchText = ""
    @State private var selectedItem: SidebarItem?
    
    private let libraryItems = SidebarItem.libraryData
    private let collections = Collection.sampleData
    
    var body: some View {
        NavigationSplitView {
            CollectionList()
            .navigationSplitViewColumnWidth(min: 220, ideal: 250, max: 300)
        } detail: {
            BookmarkList(selectedItem: selectedItem)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 900, minHeight: 600)
    }
}

// MARK: - Book Item

struct BookItem: Identifiable {
    let id = UUID()
    let title: String
    let author: String
    let coverColor: Color
    let progress: Int? // Percentage, nil means not started
    let isNew: Bool
}


// MARK: - Sample Data

extension SidebarItem {
    static let libraryData: [SidebarItem] = [
        SidebarItem(name: "All", icon: "books.vertical"),
        SidebarItem(name: "Want to Read", icon: "bookmark"),
        SidebarItem(name: "Finished", icon: "checkmark.circle"),
        SidebarItem(name: "Books", icon: "book.closed"),
        SidebarItem(name: "Audiobooks", icon: "headphones"),
        SidebarItem(name: "PDFs", icon: "doc"),
        SidebarItem(name: "My Samples", icon: "doc.text")
    ]
}

extension Collection {
    static let sampleData: [Collection] = [
        Collection(name: "My Books", icon: "line.3.horizontal"),
        Collection(name: "IOS dev", icon: "line.3.horizontal")
    ]
}

extension BookItem {
    static let sampleData: [BookItem] = [
        BookItem(title: "Eloquent Ruby", author: "Russ Olsen", coverColor: .red, progress: 40, isNew: false),
        BookItem(title: "假装生活在唐朝", author: "张东海", coverColor: Color(red: 0.7, green: 0.2, blue: 0.2), progress: nil, isNew: true),
        BookItem(title: "Healthy Sleep Habits", author: "Marc Weissbluth", coverColor: .white, progress: 24, isNew: false),
        BookItem(title: "Wicked Cool Shell Scripts", author: "Dave Taylor", coverColor: .yellow, progress: nil, isNew: true),
        BookItem(title: "The Linux Command Line", author: "William Shotts", coverColor: .yellow, progress: nil, isNew: true),
        BookItem(title: "JavaScript Ninja", author: "John Resig", coverColor: Color(red: 0.6, green: 0.3, blue: 0.2), progress: 20, isNew: false),
        BookItem(title: "Rails Guides", author: "Rails Team", coverColor: .red, progress: 5, isNew: false),
        BookItem(title: "Metaprogramming Ruby", author: "Paolo Perrotta", coverColor: .white, progress: 68, isNew: false)
    ]
}

// MARK: - Preview

//#Preview {
//    CollectionView()
//}
