import SwiftUI
import AppKit
import Kingfisher

struct ContentView: View {
    @EnvironmentObject var cabinet: OkamuraCabinet
    
    @State private var present = false
    
    @State private var parentId: UUID?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Toolbar(present: $present) {
                    let directory = Directory(id: UUID(), name: "123", parentId: parentId)
                    cabinet.insert(entry: directory, anchor: parentId)
                }
                OutlineView(entries: $cabinet.entries) {
                    self.parentId = $0
                }
            }
            .sheet(isPresented: $present, onDismiss: nil) {
                CraftModalView()
                    .background(Color(NSColor.windowBackgroundColor))
                    .cornerRadius(8)
                    .interactiveDismissDisabled(true)
            }
        }
        .frame(minWidth: 300, minHeight: 400)
    }
}



