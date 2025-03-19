import SwiftUI
import AppKit
import Kingfisher

struct ContentView: View {
    @EnvironmentObject var cabinet: OkamuraCabinet
    
    @State private var present = false
    
    @State private var anchorId: UUID?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Toolbar(present: $present) {
                    let directory = Directory(id: UUID(), name: "123")
                    cabinet.relocate(entry: directory, anchorId: anchorId)
                }
                OutlineView(entries: $cabinet.entries) {
                    self.anchorId = $0
                }
            }
            .sheet(isPresented: $present, onDismiss: nil) {
                CraftModalView(anchorId: $anchorId)
                    .background(Color(NSColor.windowBackgroundColor))
                    .cornerRadius(8)
                    .interactiveDismissDisabled(true)
            }
        }
        .frame(minWidth: 300, minHeight: 400)
    }
}



