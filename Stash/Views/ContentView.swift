import SwiftUI
import AppKit

struct ContentView: View {
    
    @State private var data: [Entry] = kEntries
    
    var body: some View {
        OutlineView(items: $data)
            .frame(minWidth: 300, minHeight: 400)
    }
    
}



