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
                    let name = cabinet.directoryDefaultName(anchorId: anchorId)
                    let directory = Directory(id: UUID(), name: name)
                    cabinet.relocate(entry: directory, anchorId: anchorId)
                    
                    let deadlineTime = DispatchTime.now() + 0.25
                    DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
                        NotificationCenter.default.post(name: .tapViewTapped, object: directory)
                    }
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



