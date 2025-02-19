import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var cabinet: OkamuraCabinet
    
    var body: some View {
        OutlineView(items: $cabinet.entries)
            .frame(minWidth: 300, minHeight: 400)
    }
    
}



