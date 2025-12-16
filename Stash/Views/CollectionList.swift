//
//  CollectionList.swift
//  Stash
//
//  Created by Yan Meng on 2025/12/16.
//

import SwiftUI

struct CollectionList: View {
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
//#Preview {
//    CollectionList()
//}
