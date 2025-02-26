import SwiftUI
import AppKit
import Kingfisher

struct ContentView: View {
    @EnvironmentObject var cabinet: OkamuraCabinet
    @State private var present = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Toolbar(present: $present)
                OutlineView(items: $cabinet.entries)
            }
            .sheet(isPresented: $present, onDismiss: nil) {
                CraftModalView()
                    .background(Color(NSColor.windowBackgroundColor))
                    .cornerRadius(8)
                    .interactiveDismissDisabled(true)
            }
        }
        .frame(minWidth: 300, minHeight: 400)
        .task {
            // TODO: move to creating.
            do {
                let x = try await Dominator().fetchWebPageTitle(from: URL(string: "https://www.baidu.com")!)
                print(x)
            } catch {
                print(error)
            }
            
        }
    }
}



