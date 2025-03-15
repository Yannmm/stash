import SwiftUI
import AppKit
import Kingfisher

struct ContentView: View {
    @EnvironmentObject var cabinet: OkamuraCabinet
    @State private var present = false
    
    @State private var addFolder = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Toolbar(present: $present) {
                    addFolder = true
                }
                OutlineView(items: $cabinet.entries, addFolder: $addFolder)
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



