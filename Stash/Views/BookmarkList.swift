//
//  BookmarkList.swift
//  Stash
//
//  Created by Yan Meng on 2025/12/16.
//

import SwiftUI

struct BookmarkList: View {
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
