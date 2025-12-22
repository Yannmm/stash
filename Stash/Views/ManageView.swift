//
//  ManageView.swift
//  Stash
//
//  Created by Yan Meng on 2025/12/16.
//

import SwiftUI
import AppKit

// Refer to https://dribbble.com/shots/14567500-Bookmark-app-v2

// MARK: - Data Models

struct Folder: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let count: Int
}

struct ClipTag: Identifiable, Hashable {
    let id = UUID()
    let name: String
}

struct Clip: Identifiable {
    let id = UUID()
    let title: String
    let domain: String
    let tags: [String]
    let dateAdded: Date
    
    var initial: String {
        String(title.prefix(1)).uppercased()
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter.string(from: dateAdded)
    }
}

// MARK: - ManageView

struct ManageView: View {
    @State private var selectedFolder: Folder?
    @State private var selectedTag: ClipTag?
    @State private var showAllClips = true
    
    var body: some View {
        HStack(spacing: 0) {
            ManageViewSidebar(
                selectedCollection: .constant(nil),
                groups: .constant([]),
                hashtags: .constant([])
            )
            .frame(width: 260)
            
            BookmarkList(
                selectedFolder: selectedFolder,
                selectedTag: selectedTag,
                showAllClips: showAllClips
            )
        }
        .frame(minWidth: 1000, minHeight: 650)
    }
}

// MARK: - Sample Data

extension Folder {
    static let sampleData: [Folder] = [
        Folder(name: "Awesome", count: 12),
        Folder(name: "Dribbble Likes", count: 45),
        Folder(name: "Grandcentral Beta", count: 8),
        Folder(name: "Inspiration", count: 156),
        Folder(name: "Read Later", count: 24)
    ]
}

extension ClipTag {
    static let sampleData: [ClipTag] = [
        ClipTag(name: "Design"),
        ClipTag(name: "Development")
    ]
}

extension Clip {
    static let sampleData: [Clip] = [
        Clip(
            title: "Misguided Nostalgia for Our Paleo Pasts",
            domain: "chronicle.com",
            tags: [],
            dateAdded: createDate(year: 2023, month: 11, day: 10)
        ),
        Clip(
            title: "Visualizing The Beatles",
            domain: "visualizingthebeatles.com",
            tags: ["Design"],
            dateAdded: createDate(year: 2023, month: 10, day: 28)
        ),
        Clip(
            title: "Design for the Other 90%",
            domain: "cooperhewitt.org",
            tags: ["Design"],
            dateAdded: createDate(year: 2023, month: 10, day: 6)
        ),
        Clip(
            title: "CSS Grid Layout Guide",
            domain: "css-tricks.com",
            tags: ["Development"],
            dateAdded: createDate(year: 2023, month: 9, day: 6)
        ),
        Clip(
            title: "Refactoring UI",
            domain: "refactoringui.com",
            tags: ["Design", "Development"],
            dateAdded: createDate(year: 2023, month: 7, day: 13)
        ),
        Clip(
            title: "The Future of Interface Design",
            domain: "interface.design",
            tags: [],
            dateAdded: createDate(year: 2023, month: 3, day: 22)
        )
    ]
    
    private static func createDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components) ?? Date()
    }
}

// MARK: - Preview

#Preview {
    ManageView()
}
