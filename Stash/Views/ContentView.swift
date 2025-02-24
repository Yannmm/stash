import SwiftUI
import AppKit

struct CustomToolbar: View {
    var body: some View {
        HStack(spacing: 16) {
            // Left side buttons
            HStack(spacing: 8) {
                Button(action: { print("Add clicked") }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)
                
                Button(action: { print("Delete clicked") }) {
                    Image(systemName: "minus")
                }
                .buttonStyle(.plain)
            }
            Spacer()
            // Center title
            Text("SwiftUI")
                .font(.headline)
            Spacer()
            // Right side buttons
            HStack(spacing: 8) {
                Button(action: { print("Search clicked") }) {
                    Image(systemName: "magnifyingglass")
                }
                .buttonStyle(.plain)
                
                Button(action: { print("Share clicked") }) {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// Then use it in ContentView
struct ContentView: View {
    @EnvironmentObject var cabinet: OkamuraCabinet
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CustomToolbar()
                Divider()
                OutlineView(items: $cabinet.entries)
            }
        }
        .frame(minWidth: 300, minHeight: 400)
    }
}





