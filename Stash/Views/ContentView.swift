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

// Helper extension for favicon URLs
extension URL {
    var faviconURL: URL? {
        guard let host = self.host else { return nil }
        return URL(string: "https://www.google.com/s2/favicons?domain=\(host)&sz=32")
    }
}

// If you want to show favicons for multiple items:
struct FaviconRow: View {
    let url: URL
    
    var body: some View {
        HStack(spacing: 4) {
            KFImage(url.faviconURL)
                .placeholder {
                    Image(systemName: "globe")
                        .resizable()
                        .frame(width: 16, height: 16)
                }
                .resizable()
                .frame(width: 16, height: 16)
            
            Text(url.host ?? "")
        }
    }
}




