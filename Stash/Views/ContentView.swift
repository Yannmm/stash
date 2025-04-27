import SwiftUI
import AppKit
import Kingfisher

struct ContentView: View {
    @EnvironmentObject var cabinet: OkamuraCabinet
    
    @State private var present = false
    @State private var anchorId: UUID?
    @State private var error: Error?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Toolbar(present: $present) {
                    do {
                        let name = cabinet.directoryDefaultName(anchorId: anchorId)
                        let directory = Group(id: UUID(), name: name)
                        try cabinet.relocate(entry: directory, anchorId: anchorId)
                        
                        let deadlineTime = DispatchTime.now() + 0.25
                        DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
                            NotificationCenter.default.post(name: .onDoubleTapRowView, object: directory)
                        }
                    } catch {
                        self.error = error
                    }
                }
                OutlineView(entries: $cabinet.storedEntries, anchorId: $anchorId, presentingModal: $present) {
                    self.anchorId = $0
                }
                ModifierKeyMonitorView(listen: !present)
                    .frame(width: 0, height: 0)
            }
            .padding()
            .sheet(isPresented: $present, onDismiss: nil) {
                CraftModalView(anchorId: $anchorId)
                    .background(Color(NSColor.windowBackgroundColor))
                    .cornerRadius(8)
                    .interactiveDismissDisabled(true)
            }
        }
        .frame(width: 600)
        .alert("Error", isPresented: Binding(
            get: { error != nil },
            set: { x in }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(error?.localizedDescription ?? "")
        }
    }
}



