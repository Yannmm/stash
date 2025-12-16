//
//  CollectionView.swift
//  Stash
//
//  Created by Yan Meng on 2025/12/16.
//

import SwiftUI
import AppKit

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
            SidebarContentView(
                searchText: $searchText,
                selectedItem: $selectedItem,
                libraryItems: libraryItems,
                collections: collections
            )
            .navigationSplitViewColumnWidth(min: 220, ideal: 250, max: 300)
        } detail: {
            DetailGridView(selectedItem: selectedItem)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 900, minHeight: 600)
    }
}

// MARK: - Sidebar Content View

private struct SidebarContentView: View {
    @Binding var searchText: String
    @Binding var selectedItem: SidebarItem?
    let libraryItems: [SidebarItem]
    let collections: [Collection]
    
    var body: some View {
        VStack(spacing: 0) {
            // Search field with top padding for traffic lights
            SidebarSearchField(text: $searchText)
                .padding(.top, 52) // Space for traffic light buttons
                .padding(.horizontal, 12)
                .padding(.bottom, 16)
            
            // Scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Apple Books Section
                    SectionView(title: "Apple Books") {
                        SidebarRow(
                            icon: "house",
                            title: "Home",
                            isSelected: false
                        )
                    }
                    
                    // Library Section
                    SectionView(title: "Library") {
                        ForEach(libraryItems) { item in
                            SidebarRow(
                                icon: item.icon,
                                title: item.name,
                                count: item.count,
                                isSelected: selectedItem?.id == item.id
                            )
                            .onTapGesture {
                                selectedItem = item
                            }
                        }
                    }
                    
                    // My Collections Section
                    SectionView(title: "My Collections") {
                        ForEach(collections) { collection in
                            SidebarRow(
                                icon: collection.icon,
                                title: collection.name,
                                isSelected: false
                            )
                        }
                        
                        // Add New Collection
                        SidebarRow(
                            icon: "plus",
                            title: "New Collection",
                            isSelected: false,
                            isAddButton: true
                        )
                    }
                }
                .padding(.horizontal, 12)
            }
            
            Spacer()
            
            // User Profile at bottom
            UserProfileRow()
                .padding(.horizontal, 12)
                .padding(.bottom, 16)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            if selectedItem == nil {
                selectedItem = libraryItems.first
            }
        }
    }
}

// MARK: - Sidebar Search Field

private struct SidebarSearchField: View {
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            
            TextField("Search", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Section View

private struct SectionView<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 8)
                .padding(.bottom, 4)
            
            content()
        }
    }
}

// MARK: - Sidebar Row

private struct SidebarRow: View {
    let icon: String
    let title: String
    var count: Int? = nil
    var isSelected: Bool
    var isAddButton: Bool = false
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(iconColor)
                .frame(width: 20)
            
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(textColor)
            
            Spacer()
            
            if let count = count {
                Text("\(count)")
                    .font(.system(size: 11))
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundFillColor)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private var iconColor: Color {
        if isAddButton {
            return .secondary
        } else if isSelected {
            return .white
        } else {
            return .primary
        }
    }
    
    private var textColor: Color {
        if isAddButton {
            return .secondary
        } else if isSelected {
            return .white
        } else {
            return .primary
        }
    }
    
    private var backgroundFillColor: Color {
        if isSelected {
            return Color.accentColor
        } else if isHovered {
            return Color(NSColor.controlBackgroundColor)
        } else {
            return Color.clear
        }
    }
}

// MARK: - User Profile Row

private struct UserProfileRow: View {
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 32, height: 32)
                .overlay(
                    Text("M")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                )
            
            Text("meng yan")
                .font(.system(size: 13))
                .foregroundStyle(.primary)
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
}

// MARK: - Detail Grid View

private struct DetailGridView: View {
    let selectedItem: SidebarItem?
    
    private let books = BookItem.sampleData
    private let columns = [
        GridItem(.adaptive(minimum: 140, maximum: 180), spacing: 24)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with top padding for unified toolbar area
            HStack {
                Text(selectedItem?.name ?? "All")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 52) // Match sidebar top padding
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            
            // Grid of books
            ScrollView {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(books) { book in
                        BookCard(book: book)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .background(Color(NSColor.textBackgroundColor))
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

// MARK: - Book Card

private struct BookCard: View {
    let book: BookItem
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Book Cover
            RoundedRectangle(cornerRadius: 4)
                .fill(book.coverColor.gradient)
                .aspectRatio(0.7, contentMode: .fit)
                .overlay(
                    VStack {
                        Spacer()
                        Text(book.title)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                            .padding(.bottom, 16)
                    }
                )
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
            
            // Bottom row with badges and actions
            HStack(spacing: 6) {
                if let progress = book.progress {
                    Text("\(progress)%")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                
                if book.isNew {
                    Text("NEW")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
                
                Spacer()
                
                if isHovered {
                    Button(action: {}) {
                        Image(systemName: "icloud.and.arrow.down")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {}) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
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

#Preview {
    CollectionView()
}
